# name: discourse-unlock
# about: A plugin to integrate the unlock protocol into your Discourse
# version: 0.1.0
# authors: camillebesse
# url: https://github.com/camillebesse/discourse-unlock

register_asset "stylesheets/unlocked.scss"

module ::Unlock
  class NoAccessLocked < StandardError; end

  CF_LOCK_ADDRESS ||= "unlock-lock"
  CF_LOCK_ICON    ||= "unlock-icon"
  CF_LOCK_GROUP   ||= "unlock-group"

  PLUGIN_NAME ||= "unlocked"
  SETTINGS    ||= "settings"
  TRANSACTION ||= "transaction"

  require_dependency "distributed_cache"

  @cache = ::DistributedCache.new("discourse-unlock")

  def self.settings
    @cache[SETTINGS] ||= PluginStore.get(::Unlock::PLUGIN_NAME, ::Unlock::SETTINGS) || {}
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
  [
    "../app/controllers/unlock_controller.rb",
    "../app/controllers/admin_unlock_controller.rb",
  ].each { |path| require File.expand_path(path, __FILE__) }

  extend_content_security_policy script_src: ["https://paywall.unlock-protocol.com/static/unlock.latest.min.js"]

  add_admin_route "unlock.title", "discourse-unlock"

  Discourse::Application.routes.append do
    get  "/admin/plugins/discourse-unlock" => "admin_unlock#index", constraints: StaffConstraint.new
    put  "/admin/plugins/discourse-unlock" => "admin_unlock#update", constraints: StaffConstraint.new
    post "/unlock" => "unlock#unlock"
  end

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

  require_dependency "topic_view"

  module TopicViewLockExtension
    def check_and_raise_exceptions(skip_staff_action)
      super
      raise ::Unlock::NoAccessLocked.new if ::Unlock.is_locked?(@guardian, @topic)
    end
  end

  ::TopicView.prepend TopicViewLockExtension

  require_dependency "application_controller"

  module ApplicationControllerLockExtension
    def preload_json
      super

      if settings = ::Unlock.settings
        store_preloaded("lock", MultiJson.dump(settings.slice("lock_network", "lock_address", "lock_icon", "lock_call_to_action")))
      end
    end
  end

  ::ApplicationController.prepend ApplicationControllerLockExtension

  class ::ApplicationController
    rescue_from ::Unlock::NoAccessLocked do
      if request.format.json?
        response = { error: "Payment Required" }

        if topic_id = params["topic_id"] || params["id"]
          if topic = Topic.find_by(id: topic_id)
            response[:lock] = topic.category.custom_fields[::Unlock::CF_LOCK_ADDRESS]
            response[:url] = topic.relative_url
          end
        end

        render_json_dump response, status: 402
      else
        rescue_discourse_actions(:payment_required, 402, include_ember: true)
      end
    end
  end
end
