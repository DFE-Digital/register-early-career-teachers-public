RSpec.shared_examples "a started on step" do |current_step:|
  subject(:step) { described_class.new(wizard:, started_on:) }

  let(:wizard) { FactoryBot.build(:register_mentor_wizard, current_step:, store:) }
  let(:store) do
    FactoryBot.build(:session_repository,
                     previous_school_mentor_at_school_periods: [])
  end

  let(:ineligible) { false }
  let(:provider_led) { true }
  let(:started_on) { { "day" => "1", "month" => "6", "year" => "2025" } }
  let(:previous_training_period) { FactoryBot.build(:training_period) }
  let(:contract_period) { FactoryBot.create(:contract_period, year: 2025, enabled: true) }
  let(:contract_period_enabled?) { contract_period.enabled }
  let(:currently_mentor_at_another_school) { false }

  describe "validations" do
    around do |example|
      travel_to(Date.new(2025, 6, 3)) { example.run }
    end

    context "when start date is in the future" do
      let(:started_on) { { "day" => "1", "month" => "11", "year" => "2025" } }

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
          expect(subject.errors[:started_on]).to include("Start date must be before 4 October 2025")
        end
      end
    end

    context "when start date is today" do
      let(:started_on) { { "day" => "3", "month" => "6", "year" => "2025" } }

      context "and the mentor is not currently mentoring at another school" do
        let(:currently_mentor_at_another_school) { false }

        it { is_expected.to be_valid }
      end

      context "and the mentor is currently mentoring at another school" do
        let(:currently_mentor_at_another_school) { true }
        let(:started_on) { Date.new(2024, 12, 1) }

        it { is_expected.to be_valid }
      end
    end

    context "when start date is in the past" do
      let(:started_on) { { "day" => "1", "month" => "6", "year" => "2025" } }

      context "and the mentor is not currently mentoring at another school" do
        let(:currently_mentor_at_another_school) { false }

        it { is_expected.to be_valid }
      end

      context "and the mentor is currently mentoring at another school" do
        let(:currently_mentor_at_another_school) { true }
        let(:started_on) { Date.new(2024, 12, 1) }

        it { is_expected.to be_valid }
      end
    end
  end

  describe "#next_step" do
    around do |example|
      travel_to(Date.new(2025, 6, 3)) { example.run }
    end

    context "when start date is in the future" do
      let(:started_on) { { "day" => "1", "month" => "7", "year" => "2025" } }

      context "when contract period is enabled" do
        let!(:contract_period) { FactoryBot.create(:contract_period, year: 2025, enabled: true) }

        it { expect(step.next_step).to eq(:check_answers) }
      end

      context "when contract period is disabled" do
        let!(:contract_period) { FactoryBot.create(:contract_period, year: 2025, enabled: false) }

        it { expect(step.next_step).to eq(:cannot_register_mentor_yet) }
      end

      context "when there is no matching contract period" do
        it { expect(step.next_step).to eq(:cannot_register_mentor_yet) }
      end
    end

    context "when start date is today" do
      let(:started_on) { { "day" => "3", "month" => "6", "year" => "2025" } }

      it { expect(step.next_step).to eq(:check_answers) }
    end

    context "when start date is in the past" do
      let(:started_on) { { "day" => "1", "month" => "6", "year" => "2025" } }
      let(:contract_period) { nil }

      it { expect(step.next_step).to eq(:check_answers) }
    end
  end
end
