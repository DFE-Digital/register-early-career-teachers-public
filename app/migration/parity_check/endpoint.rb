module ParityCheck
  class Endpoint
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :lead_provider
    attribute :method
    attribute :path
    attribute :options, default: {}

    def options=(value)
      super(value || {})
    end

    def method=(value)
      super(value&.to_sym)
    end
  end
end
