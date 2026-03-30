RSpec.describe TasksIndex::DetailedReviewSectionComponent, type: :component do
  let(:appropriate_body_period) { FactoryBot.create(:appropriate_body_period, :teaching_school_hub) }
  let(:component) { described_class.new(appropriate_body_period:) }

  describe "rendering" do
    before do
      allow(component).to receive_messages(
        number_of_claimable_ect_records: 5,
        number_of_missing_qts_records: 3,
        number_of_records_claimed_by_another_appropriate_body: 2,
        number_of_releasable_ect_records: 1
      )
      render_inline(component)
    end

    it "displays the claim section heading" do
      expect(page).to have_css("h2", text: "Check records, claim or release an ECT")
    end

    it "displays the action required section heading" do
      expect(page).to have_css("h2", text: "ECT records that may need other action")
    end

    it "displays the number of claimable ECT records" do
      expect(page).to have_css("h3", text: "5")
      expect(page).to have_css(".govuk-caption-l", text: "Check and claim ECT")
    end

    it "displays the number of missing QTS records" do
      expect(page).to have_css("h3", text: "3")
      expect(page).to have_css(".govuk-caption-l", text: "No QTS")
    end

    it "displays the number of releasable ECT records" do
      expect(page).to have_css("h3", text: "1")
      expect(page).to have_css(".govuk-caption-l", text: "Check and release ECT")
    end

    it "displays the number of records claimed by another appropriate body" do
      expect(page).to have_css("h3", text: "2")
      expect(page).to have_css(".govuk-caption-l", text: "Currently claimed by another AB")
    end
  end

  describe "#number_of_releasable_ect_records" do
    subject(:number_of_releasable_ect_record) { component.number_of_releasable_ect_records }

    let(:teacher) { FactoryBot.create(:teacher) }
    let(:school) { FactoryBot.create(:school) }
    let(:another_school) { FactoryBot.create(:school) }
    let(:appropriate_body_induction_period) { FactoryBot.create(:induction_period, :ongoing, teacher:, appropriate_body_period:) }
    let(:finished_etc_period_with_appropriate_body) do
      FactoryBot.create(
        :ect_at_school_period, teacher:, school:,
                               school_reported_appropriate_body: appropriate_body_period, started_on: 1.year.ago, finished_on: 2.weeks.ago
      )
    end
    let(:new_ect_period_with_same_appropriate_body) do
      FactoryBot.create(
        :ect_at_school_period, teacher:, school: another_school,
                               school_reported_appropriate_body: appropriate_body_period, started_on: 1.week.ago, finished_on: nil
      )
    end
    let(:new_ect_period_with_another_appropriate_body) do
      FactoryBot.create(:ect_at_school_period, teacher:, school: another_school, started_on: 1.week.ago, finished_on: nil)
    end

    before do
      # Given an appropriate body has claimed an ECT...
      appropriate_body_induction_period
    end

    context "when a school has notified us that an ECT is leaving" do
      before { finished_etc_period_with_appropriate_body }

      context "and has not specified another school" do
        it { is_expected.to eq 1 }

        context "when the AB has released the ECT" do
          before { appropriate_body_induction_period.update! number_of_terms: 3, finished_on: Date.current }

          it { is_expected.to be_zero }
        end
      end

      context "and has specified another school with the same AB" do
        before { new_ect_period_with_same_appropriate_body }

        it { is_expected.to be_zero }
      end

      context "and has specified another school with a different AB" do
        before { new_ect_period_with_another_appropriate_body }

        it { is_expected.to eq 1 }
      end
    end
  end
end
