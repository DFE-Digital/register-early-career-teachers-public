RSpec.shared_examples "a started on step" do |current_step:|

  subject(:step) { described_class.new(wizard:, started_on:) }

  let(:wizard) { FactoryBot.build(:register_mentor_wizard, current_step: :started_on, store:) }
  let(:store) do
     FactoryBot.build(:session_repository,
                        previous_school_mentor_at_school_periods: []
  ) 
  end

  let(:ineligible) { false }
  let(:provider_led) { true }
  let(:started_on) { { "day" => "10", "month" => "9", "year" => "2025" } }
  let(:previous_training_period) { FactoryBot.build(:training_period) }
  let(:contract_period) { FactoryBot.create(:contract_period, year: 2025, enabled: true) }
  let(:contract_period_enabled?) { contract_period.enabled }
  let(:currently_mentor_at_another_school) { false }

  describe "validations" do
    context "when start date is in the future" do
      let(:started_on) { Date.new(2025, 5, 2) }

      around do |example|
        travel_to(Date.new(2025, 1, 1)) { example.run }
      end

      before do
        allow(wizard.mentor).to receive(:currently_mentor_at_another_school?).and_return(currently_mentor_at_another_school)
      end

      context "and the mentor is not currently mentoring at another school" do
        let(:currently_mentor_at_another_school) { false }

        it { is_expected.to be_valid }
      end

      context "and the mentor is currently mentoring at another school" do
        let(:currently_mentor_at_another_school) { true }
        let(:latest_valid_started_on) { 4.months.from_now.to_date }

        it "is valid up to 4 months from today" do
          subject.started_on = latest_valid_started_on
          expect(subject).to be_valid
        end

        it "is invalid over 4 months from today" do
          subject.started_on = latest_valid_started_on + 1.day
          expect(subject).not_to be_valid
          expect(subject.errors[:started_on]).to include("Start date must be before 2 May 2025")
        end
      end
    end
  end

  describe "#next_step" do
    before do
      allow(wizard.mentor).to receive(:contract_period_enabled?).and_return(contract_period_enabled?)
    end

    context "when contract period is not open yet" do
      let(:contract_period) { FactoryBot.create(:contract_period, year: 2025, enabled: false) }

      it { expect(step.next_step).to eq(:cannot_register_mentor_yet) }
    end
  end
end
