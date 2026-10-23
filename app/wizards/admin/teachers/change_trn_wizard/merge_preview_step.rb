module Admin
  module Teachers
    module ChangeTRNWizard
      class MergePreviewStep < Step
        def previous_step = :enter_trn

        def next_step = :confirm_merge

        def save!
          true
        end
      end
    end
  end
end
