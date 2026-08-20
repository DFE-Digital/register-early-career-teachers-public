describe Admin::DataFixes::Processor::Result do
  subject(:result) { described_class.new(data_change:, target_object:, error:) }

  let(:data_change) { { action: "update" } }
  let(:target_object) do
    instance_double(
      TrainingPeriod,
      id: 1,
      model_name: "TrainingPeriod",
      saved_changes: "something"
    )
  end

  describe "#success?" do
    context "when there is no error" do
      let(:error) { nil }

      it { is_expected.to be_success }
    end

    context "when there is an error" do
      let(:error) { ArgumentError.new("Invalid change") }

      it { is_expected.not_to be_success }
    end
  end

  describe "#saved_change" do
    subject(:saved_change) { result.saved_change }

    context "when there is no error" do
      let(:error) { nil }

      it { is_expected.to eq({ record_identifier: "TrainingPeriod(#1)", action: "update", changes: "something" }) }
    end

    context "when there is an error" do
      let(:error) { ArgumentError.new("Invalid change") }

      it { is_expected.to be_nil }
    end
  end
end
