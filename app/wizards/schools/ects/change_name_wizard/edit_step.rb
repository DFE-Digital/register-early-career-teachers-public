module Schools
  module ECTs
    module ChangeNameWizard
      class EditStep < ECTs::Step
        include Schools::ChangeName::Editable
      end
    end
  end
end
