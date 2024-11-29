import Controller from "@ember/controller";
import { action, computed } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import Category from "discourse/models/category";
import Group from "discourse/models/group";

export default class AdminPluginsDiscourseUnlockController extends Controller {
  @computed("model.locked_category_ids")
  get lockedCategories() {
    const { locked_category_ids } = this.model;
    return locked_category_ids && locked_category_ids.length > 0
      ? Category.findByIds(locked_category_ids)
      : [];
  }

  @action
  changeLockedCategories(categories) {
    this.set("model.locked_category_ids", categories.mapBy("id"));
  }

  groupFinder(term) {
    return Group.findAll({ term });
  }

  @action
  save() {
    this.setProperties({ saving: true, saved: false });

    const {
      lock_address,
      lock_network,
      lock_icon,
      lock_call_to_action,
      locked_category_ids,
      locked_topic_icon,
      unlocked_group_name,
    } = this.model;

    return ajax("/admin/plugins/discourse-unlock.json", {
      type: "PUT",
      data: {
        lock_address,
        lock_network,
        lock_icon,
        lock_call_to_action,
        locked_category_ids,
        locked_topic_icon,
        unlocked_group_name,
      },
    })
      .then(() => this.set("saved", true))
      .catch(popupAjaxError)
      .finally(() => this.set("saving", false));
  }
}
