describe TeacherHistoryConverter::CohortCutOffDate do
  describe "#cut_off_date_for" do
    subject(:cut_off_date) { described_class.new.cut_off_date_for(cohort_year:) }

    let(:cohort_year) { 2021 }

    it "returns the date the cohort was closed" do
      expect(cut_off_date).to eq Date.new(2024, 7, 31)
    end

    context "when the cohort is 2022" do
      let(:cohort_year) { 2022 }

      it "returns the date the cohort was closed" do
        expect(cut_off_date).to eq Date.new(2025, 7, 31)
      end
    end

    context "when the cohort is not closed" do
      let(:cohort_year) { 2023 }

      it "returns the nil" do
        expect(cut_off_date).to be_nil
      end
    end
  end
end
