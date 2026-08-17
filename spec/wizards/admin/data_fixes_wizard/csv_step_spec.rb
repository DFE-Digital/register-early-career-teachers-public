RSpec.describe Admin::DataFixesWizard::CSVStep do
  subject(:current_step) { wizard.current_step }

  let(:wizard) do
    Admin::DataFixesWizard::Wizard.new(
      current_step: :csv,
      step_params: ActionController::Parameters.new(csv: params),
      author:,
      store:
    )
  end
  let(:store) { FactoryBot.build(:session_repository) }
  let(:author) { FactoryBot.build(:dfe_user, role: :product_team) }
  let(:params) { { csv_string: } }
  let(:csv_string) { "" }

  describe ".permitted_params" do
    subject(:permitted_params) { described_class.permitted_params }

    it { is_expected.to contain_exactly(:csv_string) }
  end

  describe "#previous_step" do
    subject(:previous_step) { current_step.previous_step }

    it { is_expected.to be_nil }
  end

  describe "#next_step" do
    subject(:next_step) { current_step.next_step }

    it { is_expected.to eq(:preview) }
  end

  describe "#save!" do
    subject(:save!) { current_step.save! }

    context "when the CSV is valid" do
      let(:csv_string) do
        <<~ROWS
          object_type,object_id,action,attributes
          something,1,create,"attribute1,value1,attribute2,value2"
          another_thing,2,destroy,""
        ROWS
      end

      it { is_expected.to be_truthy }

      it "persists rows in the store" do
        expect { save! }
          .to change { current_step.store.parsed_rows }
          .from(nil)
          .to(
            [
              {
                "object_type" => "something",
                "object_id" => "1",
                "action" => "create",
                "attributes" => "attribute1,value1,attribute2,value2"
              },
              {
                "object_type" => "another_thing",
                "object_id" => "2",
                "action" => "destroy",
                "attributes" => ""
              }
            ]
          )
      end

      it "has no errors" do
        save!

        expect(current_step.errors).to be_empty
      end
    end

    context "when the CSV is invalid" do
      let(:csv_string) do
        <<~ROWS
          object_type,object_id,attributes
          something,1,create,"attribute1,value1,attribute2,value2"
          another_thing,2,destroy,""
        ROWS
      end

      it { is_expected.to be_falsey }

      it "does not persist any rows in the store" do
        expect { save! }.not_to(change { current_step.store.parsed_rows })
      end

      it "propagates errors from `InlineCSV` parsing" do
        save!

        expect(current_step.errors)
          .to be_added(:csv_string, "CSV has invalid headers")
      end
    end
  end
end
