module Schools
  module Mentors
    module ChangeLeadProviderWizard
      class CheckAnswersStep < Step
        delegate :lead_provider_id, to: :wizard

        def previous_step
          :edit
        end

        def next_step
          :confirmation
        end

        def new_lead_provider_name
          new_lead_provider.name
        end

        def old_lead_provider_name
          old_lead_provider.name
        end

        def save!
          # TODO
          # CREATE A SERVICE TO HANDLE THIS LOGIC
          # old_lead_provider = lead_provider
          # ect_at_school_period.teacher.update!(corrected_name: store.name)
          # new_name = lead_provider
          # record_event(old_name, new_name)
        end

      private

        def record_event(old_name, new_name)
          # TODO - do we need to create an event for this, or does one exist?

          # ::Events::Record.teacher_name_changed_in_trs_event!(
          #   old_lead_provider_name:,
          #   new_lead_provider_name:,
          #   author:,
          #   teacher: ect_at_school_period.teacher
          # )
        end

        def new_lead_provider
          @new_lead_provider ||= ::LeadProvider.find(lead_provider_id)
        end

        # TODO Not very DRY - just copied and pasted from edit_step.rb
        def old_lead_provider
          latest_registration_choice.lead_provider
        end

        def latest_registration_choice
          @latest_registration_choice ||= MentorAtSchoolPeriods::LatestRegistrationChoices.new(trn: mentor_trn)
        end

        def mentor_trn
          mentor_at_school_period.teacher.trn
        end
      end
    end
  end
end
