module Schools
  module Mentors
    module ChangeLeadProviderWizard
      class CheckAnswersStep < Step
        def previous_step
          :edit
        end

        def next_step
          :confirmation
        end

        delegate :name, to: :new_lead_provider, prefix: true
        delegate :name, to: :old_lead_provider, prefix: true

        def save!
          MentorAtSchoolPeriods::ChangeLeadProvider.call(mentor_at_school_period,
                                                         new_lead_provider:,
                                                         old_lead_provider:,
                                                         author: wizard.author)

          true
        rescue MentorAtSchoolPeriods::ChangeLeadProvider::LeadProviderNotChangedError
          false
        end

      private

        def new_lead_provider
          @new_lead_provider ||= ::LeadProvider.find(store.lead_provider_id)
        end

        def old_lead_provider
          wizard.latest_registration_choice.lead_provider
        end
      end
    end
  end
end
