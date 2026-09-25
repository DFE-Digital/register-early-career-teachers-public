module Admin::DataFixesWizard::Steps
  class PreviewStep
    include DfE::Wizard::Step

    attribute :processed_results
    attribute :processed_changes

    delegate :state_store, to: :wizard
    delegate :parsed_rows, to: :state_store
  end
end
