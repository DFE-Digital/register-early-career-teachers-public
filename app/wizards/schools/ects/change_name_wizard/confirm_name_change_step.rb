module Schools
  module ECTs
    module ChangeNameWizard
      class ConfirmNameChangeStep < ECTs::Step
        include Schools::ChangeName::Confirmable
      end
    end
  end
end
