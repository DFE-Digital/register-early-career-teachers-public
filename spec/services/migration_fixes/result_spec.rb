describe MigrationFixes::Result do
  let(:data_change) { { action: "update" } }

  describe "#success?" do
    it "returns true when there is no error" do
      target_object = instance_double(TrainingPeriod)

      result = described_class.new(
        data_change:,
        target_object:
      )

      expect(result.success?).to be(true)
      expect(result.data_change).to eq(data_change)
      expect(result.target_object).to eq(target_object)
      expect(result.error).to be_nil
    end

    it "returns false when there is an error" do
      error = ArgumentError.new("Invalid change")

      result = described_class.new(
        data_change:,
        error:
      )

      expect(result.success?).to be(false)
      expect(result.data_change).to eq(data_change)
      expect(result.target_object).to be_nil
      expect(result.error).to equal(error)
    end
  end
end
