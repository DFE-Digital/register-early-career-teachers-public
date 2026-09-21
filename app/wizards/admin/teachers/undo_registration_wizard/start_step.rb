module Admin
  module Teachers
    module UndoRegistrationWizard
      class StartStep < Step
        def next_step
          return :select_school_period if wizard.at_school_periods.many?

          :confirm
        end
      end
    end
  end
end
