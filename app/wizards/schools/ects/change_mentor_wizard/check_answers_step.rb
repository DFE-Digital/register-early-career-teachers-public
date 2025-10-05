module Schools
  module ECTs
    module ChangeMentorWizard
      class CheckAnswersStep < Step
        include TrainingPeriodSources

        def previous_step
          return :edit unless mentor_eligible_for_training?
          return :training if store.accepting_current_lead_provider

          :lead_provider
        end

        def next_step = :confirmation

        def current_mentor = current_mentor_at_school_period.teacher
        def new_mentor = selected_mentor_at_school_period.teacher

        def save!
          ActiveRecord::Base.transaction do
            assign_mentor!

            if mentor_eligible_for_training?
              training_period = create_training_period!
              record_training_period_event!(training_period)
            end
          end

          true
        end

      private

        def assign_mentor!
          AssignMentor.new(
            author:,
            ect: ect_at_school_period,
            mentor: selected_mentor_at_school_period
          ).assign!
        end

        def create_training_period!
          TrainingPeriods::Create.provider_led(
            period: selected_mentor_at_school_period,
            started_on: earliest_possible_start_date,
            school_partnership: earliest_matching_school_partnership,
            expression_of_interest:
          ).call
        end

        def record_training_period_event!(training_period)
          Events::Record.record_teacher_starts_training_period_event!(
            author:,
            teacher: selected_mentor_at_school_period.teacher,
            school: selected_mentor_at_school_period.school,
            training_period:,
            mentor_at_school_period: selected_mentor_at_school_period,
            ect_at_school_period: nil,
            happened_at: earliest_possible_start_date
          )
        end

        def lead_provider = @lead_provider ||= selected_lead_provider
        def school = selected_mentor_at_school_period.school
        def started_on = selected_mentor_at_school_period.started_on

        def earliest_possible_start_date
          [Date.current, selected_mentor_at_school_period.started_on].max
        end
      end
    end
  end
end
