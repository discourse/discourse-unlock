import { ajax } from "discourse/lib/ajax";
import DiscourseRoute from "discourse/routes/discourse";

export default class AdminPluginsDiscourseUnlock extends DiscourseRoute {
  model() {
    return ajax("/admin/plugins/discourse-unlock.json");
  }
}
