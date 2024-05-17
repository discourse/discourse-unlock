# frozen_string_literal: true
# name: discourse-unlock
# about: A plugin to integrate the unlock protocol into your Discourse
# version: 0.1.0
# authors: camillebesse
# url: https://github.com/camillebesse/discourse-unlock

register_asset "stylesheets/unlocked.scss"

module ::Unlock
  class NoAccessLocked < StandardError
  end

  CF_LOCK_ADDRESS ||= "unlock-lock"
  CF_LOCK_ICON ||= "unlock-icon"
  CF_LOCK_GROUP ||= "unlock-group"

  PLUGIN_NAME ||= "discourse-unlock"
  PLUGIN_STORE_NAME ||= "unlocked"
  SETTINGS ||= "settings"
  TRANSACTION ||= "transaction"

  require_dependency "distributed_cache"

  @cache = ::DistributedCache.new("discourse-unlock")

  def self.settings
    @cache[SETTINGS] ||= PluginStore.get(::Unlock::PLUGIN_STORE_NAME, ::Unlock::SETTINGS) || {}
  end

  def self.clear_cache
    @cache.clear
  end

  def self.is_locked?(guardian, topic)
    return false if guardian.is_admin?
    return false if topic.category&.custom_fields&.[](CF_LOCK_ADDRESS).blank?
    !guardian&.user&.groups&.where(name: topic.category.custom_fields[CF_LOCK_GROUP])&.exists?
  end
end

after_initialize do
  require_relative "app/controllers/unlock_controller"
  require_relative "app/controllers/admin_unlock_controller"
  require_relative "lib/unlock/application_controller_extension"
  require_relative "lib/unlock/topic_view_extension"

  extend_content_security_policy script_src: [
                                   "https://paywall.unlock-protocol.com/static/unlock.latest.min.js",
                                 ]

  add_admin_route "unlock.title", "discourse-unlock"

  Discourse::Application.routes.append do
    get "/admin/plugins/discourse-unlock" => "admin_unlock#index",
        :constraints => StaffConstraint.new
    put "/admin/plugins/discourse-unlock" => "admin_unlock#update",
        :constraints => StaffConstraint.new
    post "/unlock" => "unlock#unlock"
  end

  register_category_custom_field_type(::Unlock::CF_LOCK_ADDRESS, :string)
  register_category_custom_field_type(::Unlock::CF_LOCK_ICON, :string)

  Site.preloaded_category_custom_fields << ::Unlock::CF_LOCK_ADDRESS
  Site.preloaded_category_custom_fields << ::Unlock::CF_LOCK_ICON

  add_to_serializer(:basic_category, :lock, false) do
    object.custom_fields[::Unlock::CF_LOCK_ADDRESS]
  end

  add_to_serializer(:basic_category, :include_lock?) do
    object.custom_fields[::Unlock::CF_LOCK_ADDRESS].present?
  end

  add_to_serializer(:basic_category, :lock_icon, false) do
    object.custom_fields[::Unlock::CF_LOCK_ICON]
  end

  add_to_serializer(:basic_category, :include_lock_icon?) do
    object.custom_fields[::Unlock::CF_LOCK_ADDRESS].present? &&
      object.custom_fields[::Unlock::CF_LOCK_ICON].present?
  end

  reloadable_patch do
    TopicView.prepend(Unlock::TopicViewExtension)
    ApplicationController.prepend(Unlock::ApplicationControllerExtension)
  end
end
