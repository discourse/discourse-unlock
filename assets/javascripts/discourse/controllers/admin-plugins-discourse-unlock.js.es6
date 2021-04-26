import { action, computed } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import Controller from "@ember/controller";
import { popupAjaxError } from "discourse/lib/ajax-error";
import Category from "discourse/models/category";

export default Controller.extend({
  lockedCategories: computed("locked_category_ids", function() {
    return Category.findByIds(this.locked_category_ids);
  }),

  @action
  changeLockedCategories(categories) {
    this.set("locked_category_ids", categories.mapBy("id"));
  },

  @action
  save() {
    this.setProperties({ saving: true, saved: false });

    const {
      lock_name,
      lock_address,
      lock_network,
      locked_category_ids,
      locked_topic_icon,
      unlocked_group_name,
      unlocked_user_flair_icon,
    } = this;

    debugger

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
