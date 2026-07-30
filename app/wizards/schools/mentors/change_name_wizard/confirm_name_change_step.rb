module Schools
  module Mentors
    module ChangeNameWizard
      class ConfirmNameChangeStep < Mentors::Step
        include Schools::ChangeName::Confirmable
      end
    end
  end
end
