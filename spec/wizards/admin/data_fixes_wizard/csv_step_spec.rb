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
  let(:store) { FactoryBot.build(:session_repository, parsed_rows:) }
  let(:author) { FactoryBot.build(:dfe_user, role: :product_team) }
  let(:params) { { csv_string: } }
  let(:csv_string) { "" }
  let(:parsed_rows) { nil }

  it { is_expected.to delegate_method(:errors).to(:inline_csv) }

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

    before do
      allow(Admin::DataFixes::InlineCSV)
        .to receive(:new)
        .and_return(fake_inline_csv)
    end

    context "when the CSV is valid" do
      let(:fake_inline_csv) do
        instance_double(
          Admin::DataFixes::InlineCSV,
          parse: [{ test: "something" }, { test: "another_thing" }]
        )
      end

      it { is_expected.to be_truthy }

      it "persists parsed rows in the store" do
        expect { save! }
          .to change { current_step.store.parsed_rows }
          .from(nil)
          .to([{ test: "something" }, { test: "another_thing" }])
      end
    end

    context "when the CSV is invalid" do
      let(:fake_inline_csv) do
        instance_double(Admin::DataFixes::InlineCSV, parse: false)
      end

      it { is_expected.to be_falsey }

      it "does not persist parsed rows in the store" do
        expect { save! }.not_to(change { current_step.store.parsed_rows })
      end

      context "but there were parsed rows already in the store" do
        let(:parsed_rows) { [{ "column1" => "value1", "column2" => "value2" }] }

        it { is_expected.to be_falsey }

        it "clears the existing processed changes from the store" do
          expect { save! }
            .to change { current_step.store.parsed_rows }
            .from([{ "column1" => "value1", "column2" => "value2" }])
            .to(nil)
        end
      end
    end
  end

  describe "pre-populating attributes" do
    context "when there are parsed rows in the store" do
      let(:params) { {} }
      let(:parsed_rows) do
        [
          { "column1" => "value1", "column2" => "value2" },
          { "column1" => "value3", "column2" => "value4" },
        ]
      end

      it "pre-populates the csv string" do
        expect(current_step.csv_string).to eq <<~ROWS
          column1,column2
          value1,value2
          value3,value4
        ROWS
      end
    end

    context "when there are not parsed rows in the store" do
      let(:params) { {} }
      let(:parsed_rows) { nil }

      it "does not pre-populate the csv string" do
        expect(current_step.csv_string).to be_nil
      end
    end
  end
end
