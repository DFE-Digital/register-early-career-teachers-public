module ParityCheck
  class Endpoint < ApplicationRecord
    self.table_name = "parity_check_endpoints"

    has_many :requests

    validates :path, presence: true
    validates :method, presence: true, inclusion: { in: %i[get post put] }
    validate :options_is_a_hash

    def method
      super&.to_sym
    end

    def options=(value)
      super(value || {})
    end

    def options
      value = super
      value.deep_symbolize_keys if value.respond_to?(:deep_symbolize_keys)
    end

  private

    def options_is_a_hash
      errors.add(:options, "Options must be a hash") unless options.is_a?(Hash)
    end
  end
end
