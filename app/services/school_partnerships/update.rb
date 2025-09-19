module SchoolPartnerships
  class Update
    attr_reader :school_partnership, :lead_provider_delivery_partnership

    def initialize(school_partnership:, lead_provider_delivery_partnership:)
      @school_partnership = school_partnership
      @lead_provider_delivery_partnership = lead_provider_delivery_partnership
    end

    def update
      ActiveRecord::Base.transaction do
        school_partnership.tap do |school_partnership|
          previous_delivery_partner = school_partnership.delivery_partner
          school_partnership.update!(lead_provider_delivery_partnership:)
          modifications = school_partnership.saved_changes
          lead_provider = school_partnership.lead_provider
          Events::Record.record_school_partnership_updated_event!(author: Events::LeadProviderAPIAuthor.new(lead_provider:), school_partnership:, previous_delivery_partner:, modifications:)
        end
      end
    end
  end
end
