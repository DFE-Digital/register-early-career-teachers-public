describe TeacherHistoryConverter::PostInductionCompletionComboCheck do
  subject(:combo_check) { described_class.new.keep?(profile_id:, lead_provider_id:, cohort_year:) }

  let(:profile_id) { "0060d02a-72da-45d1-863c-2bd71e79809f" }
  let(:lead_provider_id) { "da470c27-05a6-4f5b-b9a9-58b04bfcc408" }
  let(:cohort_year) { 2023 }

  describe "#keep?" do
    context "when combo matches an entry in the keep list" do
      it "returns true" do
        expect(combo_check).to be_truthy
      end
    end

    context "when the participant_profile_id doesn't match the rest of the combo" do
      let(:profile_id) { "068fa196-6e64-494c-b9ef-419b068ee088" }

      it "returns false" do
        expect(combo_check).to be_falsy
      end
    end

    context "when the lead_provider_id doesn't match the rest of the combo" do
      let(:lead_provider_id) { "068fa196-6e64-494c-b9ef-419b068ee088" }

      it "returns false" do
        expect(combo_check).to be_falsy
      end
    end

    context "when the cohort_year doesn't match the rest of the combo" do
      let(:cohort_year) { 2022 }

      it "returns false" do
        expect(combo_check).to be_falsy
      end
    end
  end
end
