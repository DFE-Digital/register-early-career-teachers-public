RSpec.describe ECTHelper, type: :helper do
  let(:started_on) { 10.days.ago }
  let(:school) { FactoryBot.create(:school) }
  let(:trs_induction_status) { nil }
  let(:ect_teacher) { FactoryBot.create(:teacher, trs_induction_status:) }
  let!(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, teacher: ect_teacher, school:, started_on:) }
  let!(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :ongoing, school:, started_on:) }

  describe "#ect_mentor_details" do
    subject { helper.ect_mentor_details(ect_at_school_period) }

    let(:default_link_text) { "Assign a mentor for this ECT" }

    it { is_expected.to have_link(default_link_text) }

    context "when the ECT has a mentor assigned" do
      before do
        FactoryBot.create(:mentorship_period, :ongoing, mentee: ect_at_school_period, mentor: mentor_at_school_period, started_on:)
      end

      it { is_expected.to have_link(latest_mentor_name(ect_at_school_period), href: schools_mentor_path(mentor_at_school_period)) }
      it { is_expected.not_to have_link(default_link_text) }
    end
  end

  describe "#ect_status" do
    context "when the ECT is leaving" do
      before do
        ect_at_school_period.update!(finished_on: Time.zone.today + 1.day, reported_leaving_by_school_id: school.id)
      end

      it "returns a yellow 'Leaving school' tag" do
        expect(helper.ect_status(ect_at_school_period, current_school: school)).to have_css("strong.govuk-tag.govuk-tag--yellow", text: "Leaving school")
      end

      it "does not show the leaving tag when current_school is not provided" do
        expect(helper.ect_status(ect_at_school_period)).not_to have_css("strong.govuk-tag.govuk-tag--yellow", text: "Leaving school")
      end
    end

    context "when the ECT has a TRS induction status" do
      context "when the status is Passed" do
        let(:trs_induction_status) { "Passed" }

        it "returns a green 'Registered' tag" do
          expect(helper.ect_status(ect_at_school_period)).to have_css("strong.govuk-tag.govuk-tag--blue", text: "Completed induction")
        end
      end

      context "when the status is Failed" do
        let(:trs_induction_status) { "Failed" }

        it "returns a green 'Registered' tag" do
          expect(helper.ect_status(ect_at_school_period)).to have_css("strong.govuk-tag.govuk-tag--pink", text: "Failed induction")
        end
      end

      context "when the status is Exempt" do
        let(:trs_induction_status) { "Exempt" }

        it "returns a green 'Registered' tag" do
          expect(helper.ect_status(ect_at_school_period)).to have_css("strong.govuk-tag.govuk-tag--grey", text: "Exempt")
        end
      end
    end

    context "when the ECT has an empty TRS induction status" do
      context "when the ECT has a current mentor" do
        let!(:mentorship_period) { FactoryBot.create(:mentorship_period, :ongoing, mentee: ect_at_school_period, mentor: mentor_at_school_period, started_on:) }

        it "returns a green 'Registered' tag" do
          expect(helper.ect_status(ect_at_school_period)).to have_css("strong.govuk-tag.govuk-tag--green", text: "Registered")
        end
      end

      context "when the ECT does not have a current mentor" do
        it "returns a red 'Action required' tag" do
          expect(helper.ect_status(ect_at_school_period)).to have_css("strong.govuk-tag.govuk-tag--red", text: "Action required")
        end
      end
    end
  end
end
