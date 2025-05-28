import Component from "@ember/component";
import { classNames, tagName } from "@ember-decorators/component";
import { i18n } from "discourse-i18n";

@tagName("")
@classNames("category-custom-security-outlet", "lock-warning")
export default class LockWarning extends Component {
  static shouldRender({ category }) {
    return category?.lock;
  }

  <template>
    <p class="alert">{{i18n "unlock.category_security_warning"}}</p>
  </template>
}
