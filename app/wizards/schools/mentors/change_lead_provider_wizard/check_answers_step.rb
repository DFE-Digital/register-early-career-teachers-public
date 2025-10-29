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
          MentorAtSchoolPeriods::ChangeLeadProvider.new(mentor_at_school_period:,
                                                        lead_provider: new_lead_provider,
                                                        author: wizard.author).call
        end

      private

        def record_event(old_name, new_name)
          # EVENTS_TODO: - do we need to create an event for this, or does one exist?

          # ::Events::Record.teacher_name_changed_in_trs_event!(
          #   old_lead_provider_name:,
          #   new_lead_provider_name:,
          #   author:,
          #   teacher: ect_at_school_period.teacher
          # )
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
