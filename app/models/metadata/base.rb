module Metadata
  class Base < ApplicationRecord
    class UpdateRestrictedError < StandardError; end

    self.abstract_class = true

    before_update :ensure_metadata_namespace

    def self.bypass_update_restrictions
      previous = Thread.current[:bypass_update_restrictions]
      Thread.current[:bypass_update_restrictions] = true
      yield
    ensure
      Thread.current[:bypass_update_restrictions] = previous
    end

  private

    def ensure_metadata_namespace
      return if Thread.current[:bypass_update_restrictions]

      # The current class/base class will always be in the call stack
      # and so should be ignored.
      ignored_callers = [self.class.name, self.class.superclass.name]

      allowed = caller
        .reject { |c| ignored_callers.any? { c.include?(it) } }
        .any? { |c| c.include?("Metadata::") }
      raise UpdateRestrictedError, "Updates to #{self.class.name} are only allowed from the Metadata namespace" unless allowed
    end
  end
end
