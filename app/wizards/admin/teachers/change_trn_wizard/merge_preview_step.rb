module Admin
  module Teachers
    module ChangeTRNWizard
      class MergePreviewStep < Step
        def previous_step = :enter_trn

        def next_step = :confirm

        def save!
          store.merge_previewed = true
          true
        end
      end
    end
  end
end
