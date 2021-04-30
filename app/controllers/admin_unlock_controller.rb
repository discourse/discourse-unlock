# frozen_string_literal: true

class AdminUnlockController < Admin::AdminController
  def index
    render json: ::Unlock.settings
  end

  def update
    address = params[:lock_address].presence || ""
    address = address[/0x\h{40}/i]&.downcase

    network = params[:lock_network].to_i
    network = 4 if network != 1

    category_ids = params[:locked_category_ids]
    categories = Category.where(id: category_ids)

    topic_icon = params[:locked_topic_icon].presence

    group_name = Group.where(name: params[:unlocked_group_name]).limit(1).pluck(:name).first

    categories.each do |category|
      category.custom_fields[::Unlock::CF_LOCK_ADDRESS] = address

      category.custom_fields[::Unlock::CF_LOCK_ICON] = topic_icon || "key"

      group_names = ((category.custom_fields[::Unlock::CF_LOCK_GROUPS] || "").split(",") << group_name).uniq
      category.custom_fields[::Unlock::CF_LOCK_GROUPS] = Group.where(name: group_names).pluck(:name).join(",")

      category.save!
    end

    PluginStore.set(::Unlock::PLUGIN_NAME, ::Unlock::SETTINGS, {
      lock_address: address,
      lock_network: network,
      locked_category_ids: categories.pluck(:id),
      locked_topic_icon: topic_icon,
      unlocked_group_name: group_name,
    })

    ::Unlock.clear_cache

    render json: success_json
  end
end
