import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import Controller from "@ember/controller";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { not } from "@ember/object/computed";

export default Controller.extend({
  @action
  save() {
    this.setProperties({ saving: true, saved: false });

    const {
      lock_name,
      lock_address,
      lock_network,
      locked_categories,
      locked_topic_icon,
      unlocked_group_name,
      unlocked_user_flair_icon,
    } = this.get("model");

    const locked_category_ids = (locked_categories || []).map(c => c.id);

    return ajax("/admin/plugins/discourse-unlock.json", {
      type: "PUT",
      data: {
        lock_name,
        lock_address,
        lock_network,
        locked_category_ids,
        locked_topic_icon,
        unlocked_group_name,
        unlocked_user_flair_icon,
      },
    })
    .then(() => this.set("saved", true))
    .catch(popupAjaxError)
    .finally(() => this.set("saving", false));
  }
});
