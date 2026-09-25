RSpec.describe Admin::DataFixesWizard::Steps::CSVStep do
  subject(:current_step) { wizard.current_step }

  let(:wizard) do
    Admin::DataFixesWizard::Wizard.new(
      current_step: :csv,
      current_step_params: ActionController::Parameters.new(csv: params),
      state_store:
    )
  end
  let(:state_store) { Admin::DataFixesWizard::StateStore.new(repository:) }
  let(:repository) { DfE::Wizard::Repository::InMemory.new }

  let(:params) { { csv_string: } }
  let(:csv_string) { "" }

  describe ".permitted_params" do
    subject(:permitted_params) { described_class.permitted_params }

    it { is_expected.to contain_exactly(:csv_string) }
  end

  describe "validations" do
    context "when the CSV string is blank" do
      let(:csv_string) { "" }

      it { is_expected.to have_error(:csv_string, "CSV can’t be blank") }
    end

    context "when the CSV string is missing" do
      let(:csv_string) { nil }

      it { is_expected.to have_error(:csv_string, "CSV can’t be blank") }
    end

    context "when the CSV string is present" do
      let(:csv_string) do
        <<~ROWS
          column1,column2
          value1,value2
          value3,value4
        ROWS
      end

      it { is_expected.to be_valid }
    end
  end
end
