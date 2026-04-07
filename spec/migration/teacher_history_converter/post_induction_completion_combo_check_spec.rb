describe TeacherHistoryConverter::PostInductionCompletionComboCheck do
  subject(:combo_checker) { described_class.new(profile_id:, lead_provider_id:, cohort_year:, csv_path:) }

  let(:csv_path) { file_fixture("post_induction_completion_combos_to_keep.csv") }
  let(:profile_id) { "0060d02a-72da-45d1-863c-2bd71e79809f" }
  let(:lead_provider_id) { "da470c27-05a6-4f5b-b9a9-58b04bfcc408" }
  let(:cohort_year) { 2023 }

  describe "#keep?" do
    context "when combo matches an entry in the keep list" do
      it "returns true" do
        expect(combo_checker).to be_keep
      end
    end

    context "when the participant_profile_id doesn't match the rest of the combo" do
      let(:profile_id) { "068fa196-6e64-494c-b9ef-419b068ee088" }

      it "returns false" do
        expect(combo_checker).not_to be_keep
      end
    end

    context "when the lead_provider_id doesn't match the rest of the combo" do
      let(:lead_provider_id) { "068fa196-6e64-494c-b9ef-419b068ee088" }

      it "returns false" do
        expect(combo_checker).not_to be_keep
      end
    end

    context "when the cohort_year doesn't match the rest of the combo" do
      let(:cohort_year) { 2022 }

      it "returns false" do
        expect(combo_checker).not_to be_keep
      end
    end
  end
end
