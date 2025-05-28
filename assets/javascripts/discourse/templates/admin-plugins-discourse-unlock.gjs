import { fn, hash } from "@ember/helper";
import RouteTemplate from "ember-route-template";
import groupSelector from "discourse/components/group-selector";
import saveControls from "discourse/components/save-controls";
import textField from "discourse/components/text-field";
import htmlSafe from "discourse/helpers/html-safe";
import { i18n } from "discourse-i18n";
import categorySelector from "select-kit/components/category-selector";
import iconPicker from "select-kit/components/icon-picker";

export default RouteTemplate(
  <template>
    <section class="form-horizontal settings">
      <div class="row setting">
        <div class="setting-label">
          {{i18n "unlock.settings.lock_address.label"}}
        </div>
        <div class="setting-value">
          {{textField value=@controller.model.lock_address placeholder="0x..."}}
          <div class="desc">
            {{htmlSafe (i18n "unlock.settings.lock_address.desc")}}
          </div>
        </div>
      </div>
      <div class="row setting">
        <div class="setting-label">
          {{i18n "unlock.settings.lock_network.label"}}
        </div>
        <div class="setting-value">
          {{textField value=@controller.model.lock_network}}
          <div class="desc">
            {{i18n "unlock.settings.lock_network.desc"}}
          </div>
        </div>
      </div>
      <div class="row setting">
        <div class="setting-label">
          {{i18n "unlock.settings.lock_icon.label"}}
        </div>
        <div class="setting-value">
          {{textField
            value=@controller.model.lock_icon
            placeholder="https://..."
          }}
          <div class="desc">
            {{i18n "unlock.settings.lock_icon.desc"}}
          </div>
        </div>
      </div>
      <div class="row setting">
        <div class="setting-label">
          {{i18n "unlock.settings.lock_call_to_action.label"}}
        </div>
        <div class="setting-value">
          {{textField
            value=@controller.model.lock_call_to_action
            placeholder="Purchase your NFT membership now!"
          }}
          <div class="desc">
            {{i18n "unlock.settings.lock_call_to_action.desc"}}
          </div>
        </div>
      </div>
      <div class="row setting">
        <div class="setting-label">
          {{i18n "unlock.settings.unlocked_group_name.label"}}
        </div>
        <div class="setting-value">
          {{groupSelector
            groupNames=@controller.model.unlocked_group_name
            single="true"
            groupFinder=@controller.groupFinder
          }}
          <div class="desc">
            {{i18n "unlock.settings.unlocked_group_name.desc"}}
          </div>
        </div>
      </div>
      <div class="row setting">
        <div class="setting-label">
          {{i18n "unlock.settings.locked_categories.label"}}
        </div>
        <div class="setting-value">
          {{categorySelector
            categories=@controller.lockedCategories
            onChange=@controller.changeLockedCategories
          }}
          <div class="desc">
            {{i18n "unlock.settings.locked_categories.desc"}}
          </div>
        </div>
      </div>
      <div class="row setting">
        <div class="setting-label">
          {{i18n "unlock.settings.locked_topic_icon.label"}}
        </div>
        <div class="setting-value">
          {{iconPicker
            value=@controller.model.locked_topic_icon
            options=(hash maximum=1)
            onChange=(fn (mut @controller.model.locked_topic_icon))
          }}
          <div class="desc">
            {{i18n "unlock.settings.locked_topic_icon.desc"}}
          </div>
        </div>
      </div>
    </section>

    {{saveControls
      model=@controller.model
      action=@controller.save
      saved=@controller.saved
    }}
  </template>
);
