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
          ApplicationRecord.transaction do
            result = MentorAtSchoolPeriods::ChangeLeadProvider.new(mentor_at_school_period:,
                                                                   lead_provider: new_lead_provider,
                                                                   author: wizard.author).call

            record_event if result
            result
          end
        end

      private

        def record_event
          ::Events::Record.record_mentor_lead_provider_updated_event!(
            old_lead_provider_name:,
            new_lead_provider_name:,
            author: wizard.author,
            mentor_at_school_period:,
            school: mentor_at_school_period.school,
            teacher: mentor_at_school_period.teacher,
            happened_at: Time.current
          )
        end

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
