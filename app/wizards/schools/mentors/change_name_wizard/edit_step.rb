module Schools
  module Mentors
    module ChangeNameWizard
      class EditStep < Mentors::Step
        include Schools::ChangeName::Editable
      end
    end
  end
end
