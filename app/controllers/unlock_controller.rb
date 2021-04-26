# frozen_string_literal: true

class UnlockController < ApplicationController
  def unlock
    lock = params.require(:lock)
    wallet = params.require(:wallet)
    transaction = params.require(:transaction)

    return unless current_user
    return unless settings = PluginStore.get(::Unlock::PLUGIN_NAME, ::Unlock::SETTINGS)
    return if settings["lock_address"].blank? || settings["lock_address"] != lock.downcase
    return unless group = Group.find_by(name: settings["unlocked_group_name"])

    group.users << current_user

    value = {
      lock: lock,
      wallet: wallet,
      transaction: transaction,
    }

    PluginStore.set(::Unlock::PLUGIN_NAME, "#{::Unlock::TRANSACTION}_#{current_user.id}", value)

    render json: success_json
  end
end
