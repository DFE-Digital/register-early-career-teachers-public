module Schools
  module ECTs
    module ChangeTrainingProgrammeWizard
      class CheckAnswersStep < Step
        def previous_step
          if new_training_programme == "provider_led"
            :lead_provider
          else
            :edit
          end
        end

        def next_step = :confirmation

        def current_training_programme
          if new_training_programme == "provider_led"
            "school_led"
          else
            "provider_led"
          end
        end

        def new_training_programme = store.training_programme

        def new_lead_provider_name
          return unless new_training_programme == "provider_led"

          lead_provider.name
        end

        def save!
          if new_training_programme == "provider_led"
            switch_training_programme_to_provider_led!
          else
            switch_training_programme_to_school_led!
          end

          record_training_programme_updated_event!
          true
        end

      private

        def switch_training_programme_to_provider_led!
          ECTAtSchoolPeriods::SwitchTraining.to_provider_led(
            ect_at_school_period,
            author:,
            lead_provider:
          )
        end

        def switch_training_programme_to_school_led!
          ECTAtSchoolPeriods::SwitchTraining.to_school_led(
            ect_at_school_period,
            author:
          )
        end

        def record_training_programme_updated_event!
          old_training_programme = current_training_programme
          Events::Record.record_teacher_training_programme_updated_event!(
            old_training_programme:,
            new_training_programme:,
            author:,
            ect_at_school_period:,
            school: ect_at_school_period.school,
            teacher: ect_at_school_period.teacher,
            happened_at: Time.current
          )
        end

        def lead_provider
          LeadProvider.find(store.lead_provider_id)
        end
      end
    end
  end
end
