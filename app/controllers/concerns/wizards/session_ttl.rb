# Adds TTL-based expiry to wizard session stores to avoid stale session data
# hanging around when a user abandons a flow. This is a safety net that keeps
# multi-tab sessions usable while clearing long-idle ones.
#
# Usage in a wizard controller:
# - include this concern
# - call expire_store_if_stale before the wizard is initialized
# - call touch_store after initialization so active sessions extend TTL
#
# Example:
#   class Admin::ExampleWizardController < AdminController
#     include Wizards::SessionTTL
#
#     SESSION_TTL = 90.minutes
#
#     before_action :expire_store_if_stale
#     before_action :set_store
#     before_action :set_wizard
#     before_action :touch_store
#
#   private
#
#     def session_ttl
#       SESSION_TTL
#     end
#   end
#

module Wizards
  module SessionTTL
    extend ActiveSupport::Concern

    DEFAULT_TTL = 2.hours

  private

    def expire_store_if_stale
      store.reset if store_expired?
    end

    def store_expired?
      last_touched_at = store.last_touched_at
      return false if last_touched_at.blank?

      Time.zone.now.to_i - last_touched_at.to_i > session_ttl
    end

    def touch_store
      store.last_touched_at = Time.zone.now.to_i
    end

    def session_ttl
      DEFAULT_TTL
    end
  end
end
