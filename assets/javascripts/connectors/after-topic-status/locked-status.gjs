import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";

const LockedStatus = <template>
  {{~#if @topic.category.lock~}}
    <span title={{i18n "unlock.locked"}} class="topic-status">
      {{~icon @topic.category.lock_icon~}}
    </span>
  {{~/if~}}
</template>;

export default LockedStatus;
