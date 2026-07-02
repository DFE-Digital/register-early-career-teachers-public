module Schools
  module ECTs
    module ChangeAppropriateBodyWizard
      class CheckAnswersStep < Step
        def previous_step = :edit
        def next_step = :confirmation

        def old_appropriate_body_name
          old_appropriate_body_period&.name || "Not reported"
        end

        delegate :name, to: :new_appropriate_body_period, prefix: :new_appropriate_body
        delegate :school, to: :ect_at_school_period

        def save!
          ApplicationRecord.transaction do
            current_appropriate_body_period = old_appropriate_body_period
            ect_at_school_period.update!(school_reported_appropriate_body: new_appropriate_body_period)

            ::Events::Record.record_teacher_appropriate_body_changed!(
              author:,
              ect_at_school_period:,
              old_appropriate_body_period: current_appropriate_body_period,
              new_appropriate_body_period:
            )
          end

          true
        end

      private

        def new_appropriate_body_period = AppropriateBodyPeriod.find(store.appropriate_body_id)

        def old_appropriate_body_period
          @old_appropriate_body_period ||= ect_at_school_period.school_reported_appropriate_body
        end

        delegate :teacher, to: :ect_at_school_period
      end
    end
  end
end
