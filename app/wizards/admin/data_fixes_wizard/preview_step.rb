module Admin::DataFixesWizard
  class PreviewStep < Step
    def previous_step = :csv
    def next_step = nil
  end
end
