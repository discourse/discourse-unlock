# frozen_string_literal: true

class AdminUnlockController < Admin::AdminController
  requires_plugin Unlock::PLUGIN_NAME

  def index
    render json: ::Unlock.settings
  end

  def update
    address = params[:lock_address].presence || ""
    address = address[/0x\h{40}/i]&.downcase

    network = params[:lock_network].to_i
    network = network > 0 ? network : 4

    icon = params[:lock_icon].presence || ""

    cta = params[:lock_call_to_action].presence || ""

    category_ids = params[:locked_category_ids]
    categories = Category.where(id: category_ids)

    if topic_icon = params[:locked_topic_icon].presence
      SvgSprite.expire_cache if DiscoursePluginRegistry.svg_icons.add?(topic_icon)
    end

    settings = ::Unlock.settings

    CategoryCustomField
      .where(category_id: settings["locked_category_ids"])
      .where(name: [::Unlock::CF_LOCK_ADDRESS, ::Unlock::CF_LOCK_ICON, ::Unlock::CF_LOCK_GROUP])
      .delete_all

    CategoryGroup
      .where(category_id: settings["locked_category_ids"])
      .where(group_id: 0)
      .where(permission_type: CategoryGroup.permission_types[:readonly])
      .update_all(permission_type: CategoryGroup.permission_types[:full])

    group_name = Group.where(name: params[:unlocked_group_name]).limit(1).pluck(:name).first

    if address
      categories.each do |category|
        cg = CategoryGroup.find_or_create_by(category: category, group_id: 0)
        cg.permission_type = CategoryGroup.permission_types[:readonly]
        cg.save!

        category.custom_fields[::Unlock::CF_LOCK_ADDRESS] = address
        category.custom_fields[::Unlock::CF_LOCK_ICON] = topic_icon || "key"
        category.custom_fields[::Unlock::CF_LOCK_GROUP] = group_name
        category.save!
      end
    end

    PluginStore.set(
      ::Unlock::PLUGIN_STORE_NAME,
      ::Unlock::SETTINGS,
      {
        lock_address: address,
        lock_network: network,
        lock_icon: icon,
        lock_call_to_action: cta,
        locked_category_ids: categories.pluck(:id),
        locked_topic_icon: topic_icon,
        unlocked_group_name: group_name,
      },
    )

    ::Unlock.clear_cache

    render json: success_json
  end
end
