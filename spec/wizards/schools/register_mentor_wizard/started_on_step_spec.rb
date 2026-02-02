RSpec.describe Schools::RegisterMentorWizard::StartedOnStep do
  subject(:step) { described_class.new(wizard:, started_on:) }

  let(:wizard) do
    instance_double(
      Schools::RegisterMentorWizard::Wizard,
      mentor: registration_store
    )
  end

  let(:registration_store) do
    double(
      "Schools::RegisterMentorWizard::RegistrationStore",
      mentoring_at_new_school_only: mentoring_only,
      became_ineligible_for_funding?: ineligible,
      provider_led_ect?: provider_led,
      previous_school_mentor_at_school_periods: [],
      previous_training_period:
    )
  end

  let(:mentoring_only) { "no" }
  let(:ineligible) { false }
  let(:provider_led) { true }
  let(:started_on) { { "day" => "10", "month" => "9", "year" => "2025" } }
  let(:previous_training_period) { FactoryBot.build(:training_period) }
  let!(:contract_period) { FactoryBot.create(:contract_period, year: 2025, enabled: true) }

  describe "validations" do
    context "when start date is in the future" do
      let(:started_on) { Date.new(2025, 5, 2) }

      around do |example|
        travel_to(Date.new(2025, 1, 1)) { example.run }
      end

      before do
        allow(registration_store).to receive(:currently_mentor_at_another_school?).and_return(currently_mentor_at_another_school)
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
    context "when mentor is ineligible for funding" do
      let(:ineligible) { true }

      it { expect(step.next_step).to eq(:check_answers) }
    end

    context "when ECT is school-led" do
      let(:provider_led) { false }

      it { expect(step.next_step).to eq(:check_answers) }
    end

    context "when mentor is eligible and ECT is provider-led" do
      it { expect(step.next_step).to eq(:previous_training_period_details) }
    end

    context "when there is no previous training period" do
      let(:previous_training_period) { nil }

      it { expect(step.next_step).to eq(:programme_choices) }
    end

    context "when contract period is not open" do
      let!(:contract_period) { FactoryBot.create(:contract_period, year: 2025, enabled: false) }

      it { expect(step.next_step).to eq(:cannot_register_mentor_yet) }
    end

    context "when contract period is missing" do
      let!(:contract_period) {}

      it { expect(step.next_step).to eq(:cannot_register_mentor_yet) }
    end
  end

  describe "#previous_step" do
    context "when mentoring_at_new_school_only is 'yes'" do
      let(:mentoring_only) { "yes" }

      it { expect(step.previous_step).to eq(:mentoring_at_new_school_only) }
    end

    context "when mentoring_at_new_school_only is 'no'" do
      it { expect(step.previous_step).to eq(:email_address) }
    end
  end
end
