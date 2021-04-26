# frozen_string_literal: true

class AdminUnlockController < Admin::AdminController
  def index
    render json: PluginStore.get(::Unlock::PLUGIN_NAME, ::Unlock::SETTINGS)
  end

  def update
    name = params[:lock_name].presence

    address = params[:lock_address].presence || ""
    address = address[/0x\h{40}/i]&.downcase

    network = params[:lock_network].to_i
    network = 4 if network != 1

    category_ids = params[:locked_category_ids]
    categories = Category.where(id: category_ids)

    topic_icon = params[:locked_topic_icon].presence

    group_name = (params[:unlocked_group_name].presence || "").strip[0..20].presence

    flair_icon = params[:unlocked_user_flair_icon].presence

    group = nil

    if group_name.present?
      group = Group.find_or_create_by!(name: group_name)
      group.flair_icon = flair_icon
      group.save!
    end

    if group
      categories.each do |category|
        category.custom_fields[::Unlock::CF_LOCK_ADDRESS] = address
        category.custom_fields[::Unlock::CF_LOCK_ICON] = topic_icon.presence || "key"
        category.custom_fields[::Unlock::CF_LOCK_GROUPS] = ((category.custom_fields[::Unlock::CF_LOCK_GROUPS] || "").split(",") << group.name).uniq.join(",")
        category.save!
      end
    end

    PluginStore.set(::Unlock::PLUGIN_NAME, ::Unlock::SETTINGS, {
      lock_name: name,
      lock_address: address,
      lock_network: network,
      locked_category_ids: categories.pluck(:id),
      locked_topic_icon: topic_icon,
      unlocked_group_name: group_name,
      unlocked_user_flair_icon: flair_icon,
    })

    render json: success_json
  end
end
