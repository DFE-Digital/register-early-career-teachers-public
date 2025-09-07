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
          Events::Record.record_school_partnership_created_event!(author: Events::LeadProviderAPIAuthor.new, school_partnership:)
        end
      end
    end

  private

    def metadata_manager
      @metadata_manager ||= Metadata::Manager.new
    end
  end
end
