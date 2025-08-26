# TODO: error messages are currently consistent with ECF, however we want them to use RECT
# terminology in the service and will look to map between them somehow in a future PR.
module SchoolPartnerships
  class Create
    def create
      return false unless valid?

      ActiveRecord::Base.transaction do
        SchoolPartnership.create!(
          school:,
          lead_provider_delivery_partnership:
        ).tap do |school_partnership|
          metadata_manager.refresh_metadata!(school_partnership.school)
          Events::Record.record_school_partnership_created_event!(author: Events::LeadProviderAPIAuthor.new, school_partnership:)
        end
      end
    end

  private

    def metadata_manager
      @metadata_manager ||= Metadata::Manager.new
    end


    def metadata
      return unless school && contract_period

      @metadata ||= school.contract_period_metadata.find_by(contract_period:)
    end

    def not_school_led
      return unless metadata&.induction_programme_choice == "school_led"

      errors.add(:induction_programme_choice, "This school has only registered school-led participants. Contact the school for more information.")
    end
  end
end
