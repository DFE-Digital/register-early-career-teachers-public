RSpec.describe ECTHelper, type: :helper do
  describe "#ect_status" do
    let(:started_on) { 10.days.ago }
    let(:school) { create(:school) }
    let(:ect_teacher) { create(:teacher, trs_induction_status:) }
    let(:trs_induction_status) { nil }

    let!(:ect_at_school_period) { create(:ect_at_school_period, :active, teacher: ect_teacher, school:, started_on:) }
    let!(:mentor_at_school_period) { create(:mentor_at_school_period, :active, school:, started_on:) }

    context "when the ECT has a TRS induction status" do
      context "when the status is Passed" do
        let(:trs_induction_status) { "Passed" }

        it "returns a green 'Registered' tag" do
          expect(helper.ect_status(ect_at_school_period)).to have_css('strong.govuk-tag.govuk-tag--blue', text: 'Completed induction')
        end
      end

      context "when the status is Failed" do
        let(:trs_induction_status) { "Failed" }

        it "returns a green 'Registered' tag" do
          expect(helper.ect_status(ect_at_school_period)).to have_css('strong.govuk-tag.govuk-tag--pink', text: 'Failed induction')
        end
      end

      context "when the status is Exempt" do
        let(:trs_induction_status) { "Exempt" }

        it "returns a green 'Registered' tag" do
          expect(helper.ect_status(ect_at_school_period)).to have_css('strong.govuk-tag.govuk-tag--grey', text: 'Exempt')
        end
      end
    end

    context "when the ECT has an empty TRS induction status" do
      context "when the ECT has a current mentor" do
        let!(:mentorship_period) { create(:mentorship_period, :active, mentee: ect_at_school_period, mentor: mentor_at_school_period, started_on:) }

        it "returns a green 'Registered' tag" do
          expect(helper.ect_status(ect_at_school_period)).to have_css('strong.govuk-tag.govuk-tag--green', text: 'Registered')
        end
      end

      context "when the ECT does not have a current mentor" do
        it "returns a red 'Mentor required' tag" do
          expect(helper.ect_status(ect_at_school_period)).to have_css('strong.govuk-tag.govuk-tag--red', text: 'Mentor required')
        end
      end
    end
  end
end
