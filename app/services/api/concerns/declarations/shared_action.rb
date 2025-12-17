module API::Concerns::Declarations
  module SharedAction
    extend ActiveSupport::Concern

    included do
      include ActiveModel::Model
      include ActiveModel::Attributes

      attribute :lead_provider_id
      attribute :declaration_api_id

      validates :lead_provider_id, presence: { message: "Enter a '#/lead_provider_id'." }
      validate :lead_provider_exists
    end

  private

    def lead_provider
      @lead_provider ||= LeadProvider.find_by(id: lead_provider_id) if lead_provider_id
    end

    def declaration
      @declaration ||= Declaration.find_by!(api_id: declaration_api_id)
    end

    def lead_provider_exists
      return if errors[:lead_provider_id].any?
      return if lead_provider

      errors.add(:lead_provider_id, "The '#/lead_provider_id' you have entered is invalid.")
    end

    def author
      @author ||= Events::LeadProviderAPIAuthor.new(lead_provider:)
    end
  end
end
