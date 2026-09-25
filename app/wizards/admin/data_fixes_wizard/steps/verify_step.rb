module Admin::DataFixesWizard::Steps
  class VerifyStep
    include DfE::Wizard::Step
    include Auditable

    def self.permitted_params = auditable_params[model_name.param_key]

    attribute :confirmed_results
    attribute :confirmed_changes

    delegate :author, to: :wizard
    delegate :state_store, to: :wizard
    delegate :processed_changes, to: :state_store
  end
end
