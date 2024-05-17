# frozen_string_literal: true

module Unlock
  module TopicViewExtension
    extend ActiveSupport::Concern

    def check_and_raise_exceptions(skip_staff_action)
      super
      raise ::Unlock::NoAccessLocked.new if ::Unlock.is_locked?(@guardian, @topic)
    end
  end
end
