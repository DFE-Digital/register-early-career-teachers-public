RSpec.shared_examples "a started on step" do |current_step:|
  subject(:step) { described_class.new(wizard:, started_on: started_on_params) }

  let(:wizard) do
    FactoryBot.build(:register_mentor_wizard, current_step:, store:)
  end
  let(:store) { FactoryBot.build(:session_repository) }
  let(:contract_period) do
    FactoryBot.create(:contract_period, year: 2025, enabled: true)
  end

  let(:started_on) { Date.new(2025, 6, 1) }
  let(:started_on_params) do
    {
      "day" => started_on.day.to_s,
      "month" => started_on.month.to_s,
      "year" => started_on.year.to_s
    }
  end

  let(:previous_school_mentor_at_school_periods) { [] }

  describe ".permitted_params" do
    subject(:permitted_params) { wizard.permitted_params }

    it { is_expected.to contain_exactly(:started_on) }
  end

  describe "validations" do
    before do
      allow(wizard.mentor).to receive_messages(
        currently_mentor_at_another_school?: currently_mentor_at_another_school,
        previous_school_mentor_at_school_periods:
      )
    end

    context "when the mentor is not currently mentoring at another school" do
      let(:currently_mentor_at_another_school) { false }
      let(:previous_school_mentor_at_school_periods) { [] }

      context "and the start_date is invalid" do
        let(:started_on_params) { { "day" => "30", "month" => "2", "year" => "2025" } }

        it { is_expected.to have_error(:started_on, "Enter the date in the correct format, for example 12 03 1998") }
      end

      context "and the start date is more than 4 months in the future" do
        let(:started_on) { 4.months.from_now.advance(days: 1) }

        it { is_expected.to be_valid }
      end

      context "and the start date is 4 months in the future" do
        let(:started_on) { 4.months.from_now }

        it { is_expected.to be_valid }
      end

      context "and the start date is less than 4 months in the future" do
        let(:started_on) { 4.months.from_now.advance(days: -1) }

        it { is_expected.to be_valid }
      end
    end

    context "when the mentor is currently mentoring at another school" do
      let(:currently_mentor_at_another_school) { true }
      let(:previous_school_mentor_at_school_periods) do
        [FactoryBot.build_stubbed(:mentor_at_school_period, started_on: 2.months.ago)]
      end

      context "and the start_date is invalid" do
        let(:started_on_params) { { "day" => "30", "month" => "2", "year" => "2025" } }

        it { is_expected.to have_error(:started_on, "Enter the date in the correct format, for example 12 03 1998") }
      end

      context "and the start date is more than 4 months in the future" do
        let(:started_on) { 4.months.from_now.advance(days: 1) }

        context "and the start date is in an open contract period" do
          before do
            allow(step).to receive(:registrations_closed_for_contract_period?).and_return(false)
          end

          it { is_expected.to have_error(:started_on, "Start date must be before #{4.months.from_now.to_date.next_day.to_formatted_s(:govuk)}. You cannot register the mentor this far in advance.") }
        end

        context "and the start date falls in a contract period that is not yet open" do
          before do
            allow(step).to receive(:registrations_closed_for_contract_period?).and_return(true)
          end

          it "does not add the 4-month error so the wizard can route to cannot_register_mentor_yet" do
            expect(step).to be_valid
          end
        end
      end

      context "and the start date is 4 months in the future" do
        let(:started_on) { 4.months.from_now }

        it { is_expected.to be_valid }
      end

      context "and the start date is less than 4 months in the future" do
        let(:started_on) { 1.month.from_now }

        it { is_expected.to be_valid }
      end

      context "and the start date is before the previous school mentor at school period" do
        let(:started_on) { 3.months.ago }

        it { is_expected.to have_error(:started_on, "was registered as a mentor at their last school starting on the #{2.months.ago.to_date.to_formatted_s(:govuk)}. Enter a later date.") }
      end
    end
  end
end
