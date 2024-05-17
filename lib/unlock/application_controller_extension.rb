# frozen_string_literal: true

module Unlock
  module ApplicationControllerExtension
    extend ActiveSupport::Concern

    prepended do
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

    def preload_json
      super

      if settings = ::Unlock.settings
        store_preloaded(
          "lock",
          MultiJson.dump(
            settings.slice("lock_network", "lock_address", "lock_icon", "lock_call_to_action"),
          ),
        )
      end
    end
  end
end
