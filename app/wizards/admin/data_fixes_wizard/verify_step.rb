module Admin::DataFixesWizard
  class VerifyStep < Step
    def previous_step = :preview
    def next_step = nil

    def save! = nil

    delegate :processed_changes, to: :store
  end
end
