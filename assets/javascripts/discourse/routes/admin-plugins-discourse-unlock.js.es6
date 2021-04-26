import { ajax } from "discourse/lib/ajax";
import DiscourseRoute from "discourse/routes/discourse";
import Category from "discourse/models/category";

export default DiscourseRoute.extend({
  model() {
    return ajax("/admin/plugins/discourse-unlock.json").then((r) => {
      if (r && r.locked_category_ids) {
        r.locked_categories = Category.findByIds(r.locked_category_ids);
      }
      return r;
    });
  },
});
