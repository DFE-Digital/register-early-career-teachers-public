module Schools
  module ECTs
    module ChangeLeadProviderWizard
      class CheckAnswersStep < Step
        def previous_step = :edit
        def next_step = :confirmation

        def old_lead_provider_name
          old_lead_provider&.name.presence || withdrawn_lead_provider_name
        end

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
          @old_lead_provider ||= (current_training_lead_provider || withdrawn_lead_provider)
        end

        def current_training_lead_provider
          ECTAtSchoolPeriods::CurrentTraining
            .new(ect_at_school_period)
            .lead_provider_via_school_partnership_or_eoi
        rescue ECTAtSchoolPeriods::NoTrainingPeriodError
          nil
        end

        def new_lead_provider = LeadProvider.find(store.lead_provider_id)

        def withdrawn_lead_provider
          tp = ect_at_school_period.latest_training_period
          return unless tp&.status == :withdrawn

          if tp.only_expression_of_interest?
            tp.expression_of_interest&.lead_provider
          else
            tp.lead_provider
          end
        end

        def withdrawn_lead_provider_name
          tp = ect_at_school_period.latest_training_period
          return unless tp&.status == :withdrawn

          if tp.only_expression_of_interest?
            tp.expression_of_interest&.lead_provider&.name
          else
            tp.lead_provider_name
          end
        end
      end
    end
  end
end
