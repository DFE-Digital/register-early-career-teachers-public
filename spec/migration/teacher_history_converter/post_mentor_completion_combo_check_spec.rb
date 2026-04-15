describe TeacherHistoryConverter::PostMentorCompletionComboCheck do
  subject(:combo_check) { described_class.new.keep?(profile_id:, lead_provider_id:, cohort_year:) }

  let(:profile_id) { "3349a615-cd08-426b-8688-71df763d326a" }
  let(:lead_provider_id) { "3d7d8c90-a5a3-4838-84b2-563092bf87ee" }
  let(:cohort_year) { 2021 }

  describe "#keep?" do
    context "when combo matches an entry in the keep list" do
      it "returns true" do
        expect(combo_check).to be_truthy
      end
    end

    context "when the participant_profile_id doesn't match the rest of the combo" do
      let(:profile_id) { "eecdaeca-801f-497e-87aa-b19f34ffb30d" }

      it "returns false" do
        expect(combo_check).to be_falsy
      end
    end

    context "when the lead_provider_id doesn't match the rest of the combo" do
      let(:lead_provider_id) { "99317668-2942-4292-a895-fdb075af067b" }

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
