RSpec.describe MentorHelper, type: :helper do
  describe "#assign_existing_mentor_lead_provider_back_link" do
    subject(:back_link) { helper.assign_existing_mentor_lead_provider_back_link(wizard) }

    let(:ect_at_school_period) { FactoryBot.build_stubbed(:ect_at_school_period) }
    let(:mentor_at_school_period) { FactoryBot.build_stubbed(:mentor_at_school_period) }

    let(:wizard) do
      instance_double(
        Schools::AssignExistingMentorWizard::Wizard,
        ect_at_school_period:,
        mentor_at_school_period:,
        ect_lead_provider_available?: ect_lead_provider_available
      )
    end

    context "when the ECTs lead provider is available" do
      let(:ect_lead_provider_available) { true }

      it "returns the eligibility page" do
        expect(back_link).to eq(schools_assign_existing_mentor_wizard_review_mentor_eligibility_path)
      end
    end

    context "when the ECTs lead provider is not available" do
      let(:ect_lead_provider_available) { false }

      it "returns the page where the mentor was chosen, with the mentor preselected" do
        expect(back_link).to eq(new_schools_ect_mentorship_path(ect_at_school_period, preselect: mentor_at_school_period.id))
      end
    end
  end
end
