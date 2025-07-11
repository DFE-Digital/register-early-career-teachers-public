RSpec.describe AppropriateBodyHelper, type: :helper do
  include GovukComponentsHelper
  include GovukLinkHelper
  include GovukVisuallyHiddenHelper

  describe "#induction_programme_choices" do
    it "returns an array of FormChoice" do
      expect(induction_programme_choices).to be_an(Array)
      expect(induction_programme_choices).to all(be_a(AppropriateBodyHelper::FormChoice))
    end

    it "has identifiers for the old (pre-2025) induction choices" do
      expect(induction_programme_choices.map(&:identifier)).to eql(%w[fip cip diy])
    end

    it "has names for the old (pre-2025) induction choices" do
      expect(induction_programme_choices.map(&:name)).to eql([
        'Full induction programme',
        'Core induction programme',
        'School-based induction programme'
      ])
    end
  end

  describe "#induction_outcome_choices" do
    it "returns an array of FormChoice" do
      expect(induction_outcome_choices).to be_an(Array)
      expect(induction_outcome_choices).to all(be_a(AppropriateBodyHelper::FormChoice))
    end

    it "has identifiers for induction outcomes" do
      expect(induction_outcome_choices.map(&:identifier)).to eql(%w[pass fail])
    end

    it "has names for induction outcomes" do
      expect(induction_outcome_choices.map(&:name)).to eql(%w[Passed Failed])
    end
  end

  describe "#summary_card_for_teacher" do
    subject(:summary_card) { summary_card_for_teacher(teacher:) }

    let(:teacher) { FactoryBot.create(:teacher, trs_first_name: 'Barry', trs_last_name: 'White') }

    it "builds a summary card for a teacher" do
      expect(summary_card).to have_selector('.govuk-summary-card__title', text: 'Barry White')
      expect(summary_card).to have_selector('.govuk-summary-card__action a', text: 'Show')
      expect(summary_card).to have_selector('dt', text: 'TRN')
      expect(summary_card).to have_selector('dd', text: teacher.trn)
    end

    context "when the teacher has induction periods" do
      let(:expected_date) { "2 October 2022" }
      let!(:induction_period) do
        FactoryBot.create(
          :induction_period,
          appropriate_body: FactoryBot.create(:appropriate_body),
          teacher:,
          started_on: Date.parse(expected_date)
        )
      end

      it "displays the induction start date" do
        expect(summary_card).to have_selector('dt', text: 'Induction start date')
        expect(summary_card).to have_selector('dd', text: expected_date)
      end

      it "displays the induction status" do
        expect(summary_card).to have_selector('dt', text: 'Status')
        expect(summary_card).to have_selector('dd .govuk-tag')
      end
    end
  end

  describe "#pending_induction_submission_full_name" do
    let(:pending_induction_submission) { FactoryBot.build(:pending_induction_submission) }
    let(:fake_name) { double(PendingInductionSubmissions::Name, full_name: "Joey") }

    before do
      allow(PendingInductionSubmissions::Name).to receive(:new).with(pending_induction_submission).and_return(fake_name)
    end

    it 'calls the name service with the provided pending_induction_submission' do
      expect(pending_induction_submission_full_name(pending_induction_submission)).to eql("Joey")
    end
  end

  describe "#claimed_inductions_text" do
    it "creates the claimed inductions count heading" do
      expect(claimed_inductions_text(123)).to eql "123 claimed inductions"
    end

    context "when there is 1 claimed induction" do
      it "pluralizes the text correctly" do
        expect(claimed_inductions_text(1)).to eql "1 claimed induction"
      end
    end

    context "when there is over 1000 claimed inductions" do
      it "formats the number for easy reading" do
        expect(claimed_inductions_text(100_000)).to eql "100,000 claimed inductions"
      end
    end
  end
end
