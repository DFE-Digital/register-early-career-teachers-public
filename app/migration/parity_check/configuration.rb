module ParityCheck
  module Configuration
    extend ActiveSupport::Concern

    class UnsupportedEnvironmentError < RuntimeError; end

    def ensure_parity_check_enabled!
      raise UnsupportedEnvironmentError, "The parity check functionality is disabled for this environment" unless parity_check_enabled?
    end

    def parity_check_tokens
      parity_check_config[:tokens]
    end

    def parity_check_url(app:)
      parity_check_config["#{app}_url"]
    end

  private

    def parity_check_enabled?
      parity_check_config[:enabled]
    end

    def parity_check_config
      @parity_check_config ||= Rails.application.config.parity_check.with_indifferent_access
    end
  end
end
