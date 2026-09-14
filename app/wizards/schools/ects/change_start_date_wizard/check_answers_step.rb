module Schools
  module ECTs
    module ChangeStartDateWizard
      class CheckAnswersStep < Step
        def previous_step = :edit
        def next_step = :confirmation

        def current_start_date
          ect_at_school_period.started_on
        end

        def new_start_date
          Schools::Validation::ECTStartDate
            .new(date_as_hash: store.start_date)
            .value_as_date
        end

        def save!
          ECTAtSchoolPeriods::ChangeStartDate.change(
            ect_at_school_period,
            started_on: new_start_date,
            author:
          )

          true
        end
      end
    end
  end
end
