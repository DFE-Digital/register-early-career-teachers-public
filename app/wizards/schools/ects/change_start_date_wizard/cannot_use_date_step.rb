module Schools
  module ECTs
    module ChangeStartDateWizard
      class CannotUseDateStep < ECTs::Step
        def previous_step = :edit

        def start_date
          Schools::Validation::ECTStartDate
            .new(date_as_hash: store.start_date)
            .value_as_date
        end
      end
    end
  end
end
