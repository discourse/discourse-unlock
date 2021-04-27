import { withPluginApi } from "discourse/lib/plugin-api";
import TopicStatus from "discourse/raw-views/topic-status";
import discourseComputed from "discourse-common/utils/decorators";
import loadScript from "discourse/lib/load-script";
import PreloadStore from "discourse/lib/preload-store";
import { ajax } from "discourse/lib/ajax";

export default {
  name: "apply-unlock",

  initialize() {
    withPluginApi("0.11.2", (api) => {
      TopicStatus.reopen({
        @discourseComputed()
        statuses() {
          const results = this._super();

          if (this.topic.category.lock) {
            results.push({
              openTag: "span",
              closeTag: "span",
              title: I18n.t("unlock.locked"),
              icon: this.topic.category.lock_icon
            });
          }

          return results;
        }
      });

      api.modifyClass("model:post-stream", {
        errorLoading(result) {
          const { status } = result.jqXHR;
          const { lock, url } = result.jqXHR.responseJSON;

          if (status === 402 && lock) {
            if (api.container.lookup("current-user:main")) {
              window._redirectUrl = url;
              return window.unlockProtocol.loadCheckoutModal();
            } else {
              return api.container.lookup("route:application").replaceWith("login");
            }
          } else {
            return this._super();
          }
        }
      });

      function redirect(url) {
        if (url.startsWith("http")) {
          document.location.replace(url);
        } else {
          return DiscourseURL.handleURL(url, { replaceURL: true });
        }
      }

      const settings = PreloadStore.get("lock");

      if (settings && settings.lock_address) {
        window.addEventListener("unlockProtocol.status", ({ detail }) => {
          const { state } = detail;

          if (state === "unlocked" && window._redirectUrl) {
            if (window._wallet && window._transaction) {
              return ajax("/unlock.json", {
                type: "POST",
                data: {
                  lock: window._lock,
                  wallet: window._wallet,
                  transaction: window._transaction,
                }
              }).then(() => redirect(window._redirectUrl));
            } else {
              return redirect(window._redirectUrl);
            }
          }
        })

        window.addEventListener("unlockProtocol.authenticated", ({ detail }) => {
          const { address } = detail;
          window._wallet = address;
        })

        window.addEventListener("unlockProtocol.transactionSent", ({ detail }) => {
          const { hash, lock } = detail;
          window._transaction = hash;
          window._lock = lock;
        })

        window.unlockProtocolConfig = {
          network: settings.lock_network || 4,
          locks: {
            [settings.lock_address]: { }
          }
        };

        Ember.run.next(() => loadScript("/plugins/discourse-unlock/javascripts/unlock.js"));
      }
    });
  }
};
