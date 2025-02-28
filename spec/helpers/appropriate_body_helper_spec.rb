RSpec.describe AppropriateBodyHelper, type: :helper do
  include GovukComponentsHelper
  include GovukLinkHelper
  include GovukVisuallyHiddenHelper

  describe "#induction_programme_choices" do
    it "returns an array of InductionProgrammeChoice" do
      expect(induction_programme_choices).to be_an(Array)
      expect(induction_programme_choices).to all(be_a(AppropriateBodyHelper::InductionProgrammeChoice))
    end

    it "has keys for the old (pre-2025) induction choices" do
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

  describe "#summary_card_for_teacher" do
    let(:teacher) { FactoryBot.create(:teacher) }

    it "builds a summary card for a teacher" do
      expect(summary_card_for_teacher(teacher:)).to include(
        CGI.escapeHTML(teacher.trs_first_name),
        CGI.escapeHTML(teacher.trs_last_name)
      )
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

      it "displays the most recent induction start date" do
        expect(summary_card_for_teacher(teacher:)).to include(expected_date)
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

  describe '#trs_alerts_text' do
    context 'when alerts are present' do
      it 'returns yes' do
        expect(trs_alerts_text(true)).to include('Yes')
      end

      it 'also returns a sentence about getting more info' do
        expect(trs_alerts_text(true)).to include('Use the', 'to get more information')
        expect(trs_alerts_text(true)).to include('https://www.gov.uk/guidance/check-a-teachers-record')
      end
    end

    context 'when alerts are absent' do
      it 'returns no' do
        expect(trs_alerts_text(false)).to include('No')
      end
    end
  end
end
