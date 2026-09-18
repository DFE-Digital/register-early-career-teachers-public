module Admin
  module Teachers
    module UndoRegistrationWizard
      class StartStep < Step
        def next_step = :confirm
      end
    end
  end
end
