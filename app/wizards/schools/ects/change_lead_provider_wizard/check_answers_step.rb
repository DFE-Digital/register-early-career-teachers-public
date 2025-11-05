module Schools
  module ECTs
    module ChangeLeadProviderWizard
      class CheckAnswersStep < Step
        def previous_step = :edit
        def next_step = :confirmation

        def old_lead_provider_name = old_lead_provider&.name
        delegate :name, to: :new_lead_provider, prefix: true

        def save!
          ECTAtSchoolPeriods::ChangeLeadProvider.call(
            ect_at_school_period,
            new_lead_provider:,
            old_lead_provider:,
            author:
          )

          true
        rescue Teachers::LeadProviderChanger::LeadProviderNotChangedError
          false
        end

      private

        def old_lead_provider
          @old_lead_provider ||= ECTAtSchoolPeriods::CurrentTraining
            .new(ect_at_school_period)
            .lead_provider_via_school_partnership_or_eoi
        end

        def new_lead_provider = LeadProvider.find(store.lead_provider_id)
      end
    end
  end
end
