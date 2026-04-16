describe "Data patcher CSV data" do
  subject(:patcher) { ECF1TeacherHistory::DataPatcher.new }

  describe "data_patches.csv contents" do
    it "has no duplicate induction record rows" do
      tallies = patcher.data_patches.values_at(:induction_record_id).flatten.compact.tally

      duplicates = tallies.select { |_k, v| v > 1 }

      expect(duplicates).to be_empty
    end
  end
end
