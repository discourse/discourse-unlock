import { getOwner } from "@ember/application";
import { next } from "@ember/runloop";
import { ajax } from "discourse/lib/ajax";
import loadScript from "discourse/lib/load-script";
import { withPluginApi } from "discourse/lib/plugin-api";
import PreloadStore from "discourse/lib/preload-store";
import { withSilencedDeprecations } from "discourse-common/lib/deprecated";
import discourseComputed from "discourse-common/utils/decorators";
import I18n from "discourse-i18n";

const UNLOCK_URL =
  "https://paywall.unlock-protocol.com/static/unlock.latest.min.js";

function reset() {
  window._redirectUrl = null;
  window._lock = null;
  window._wallet = null;
  window._transaction = null;
}

export default {
  name: "apply-unlock",

  initialize() {
    withPluginApi("2.0.0", (api) => {
      withSilencedDeprecations("discourse.hbr-topic-list-overrides", () => {
        api.modifyClass(
          "raw-view:topic-status",
          (Superclass) =>
            class extends Superclass {
              @discourseComputed("topic.category.lock")
              statuses() {
                const results = super.statuses;

                if (this.topic.category?.lock) {
                  results.push({
                    openTag: "span",
                    closeTag: "span",
                    title: I18n.t("unlock.locked"),
                    icon: this.topic.category.lock_icon,
                  });
                }

                return results;
              }
            }
        );
      });
    });

    withPluginApi("0.11.2", (api) => {
      api.modifyClass("model:post-stream", {
        errorLoading(result) {
          const { status } = result.jqXHR;
          const { lock, url } = result.jqXHR.responseJSON;

          if (status === 402 && lock) {
            if (getOwner(this).lookup("service:current-user")) {
              window._redirectUrl = url;
              return loadScript(UNLOCK_URL).then(() =>
                window.unlockProtocol.loadCheckoutModal()
              );
            } else {
              return getOwner(this)
                .lookup("route:application")
                .replaceWith("login");
            }
          } else {
            return this._super(result);
          }
        },
      });

      reset();

      const settings = PreloadStore.get("lock");

      if (settings && settings.lock_address) {
        window.addEventListener("unlockProtocol.status", ({ detail }) => {
          const { state } = detail;

          if (state === "unlocked" && window._redirectUrl && window._wallet) {
            const data = {
              lock: window._lock || settings.lock_address,
              wallet: window._wallet,
            };

            if (window._transaction) {
              data["transaction"] = window._transaction;
            }

            const url = document.location.origin + window._redirectUrl;

            reset();

            return ajax("/unlock.json", { type: "POST", data }).then(() =>
              document.location.replace(url)
            );
          }
        });

        window.addEventListener(
          "unlockProtocol.authenticated",
          ({ detail }) => {
            const { address } = detail;
            window._wallet = address;
          }
        );

        window.addEventListener(
          "unlockProtocol.transactionSent",
          ({ detail }) => {
            const { hash, lock } = detail;
            window._transaction = hash;
            window._lock = lock;
          }
        );

        window.unlockProtocolConfig = {
          network: settings.lock_network || 4,
          locks: {
            [settings.lock_address]: {},
          },
          icon: settings.lock_icon,
          callToAction: {
            default: settings.lock_call_to_action,
          },
          referrer: "0x67dec02d34ea56bcf9f7c9b318298dda8c562080",
        };

        // preload unlock script
        next(() => loadScript(UNLOCK_URL));
      }
    });
  },
};
