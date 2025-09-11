module SchoolPartnerships
  class Create
    attr_reader :school, :lead_provider_delivery_partnership

    def initialize(school:, lead_provider_delivery_partnership:)
      @school = school
      @lead_provider_delivery_partnership = lead_provider_delivery_partnership
    end

    def create
      ActiveRecord::Base.transaction do
        SchoolPartnership.create!(
          school:,
          lead_provider_delivery_partnership:
        ).tap do |school_partnership|
          lead_provider = school_partnership.lead_provider
          Events::Record.record_school_partnership_created_event!(author: Events::LeadProviderAPIAuthor.new(lead_provider:), school_partnership:)
        end
      end
    end
  end
end
