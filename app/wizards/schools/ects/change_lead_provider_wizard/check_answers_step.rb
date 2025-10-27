module Schools
  module ECTs
    module ChangeLeadProviderWizard
      class CheckAnswersStep < Step
        def previous_step = :edit
        def next_step = :confirmation

        def current_lead_provider_name = current_lead_provider&.name
        def new_lead_provider_name = selected_lead_provider.name

        def save!
          ECTAtSchoolPeriods::SwitchLeadProvider.switch(
            ect_at_school_period,
            to: selected_lead_provider,
            from: current_lead_provider,
            author:
          )

          true
        end

      private

        def current_lead_provider
          @current_lead_provider ||= ECTAtSchoolPeriods::CurrentTraining
            .new(ect_at_school_period)
            .lead_provider_via_school_partnership_or_eoi
        end

        def selected_lead_provider = LeadProvider.find(store.lead_provider_id)
      end
    end
  end
end
