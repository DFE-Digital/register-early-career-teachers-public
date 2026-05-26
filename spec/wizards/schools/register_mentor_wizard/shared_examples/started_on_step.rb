RSpec.shared_examples "a started on step" do |current_step:|
  subject(:step) { described_class.new(wizard:, started_on: started_on_params) }

  let(:wizard) do
    FactoryBot.build(:register_mentor_wizard, current_step:, store:)
  end
  let(:store) { FactoryBot.build(:session_repository, trs_first_name: "Johnnie", trs_last_name: "Walker") }
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
      let(:previous_school) do
        FactoryBot.create(:school, :independent).tap do |school|
          school.gias_school.update!(name: "Springfield Primary")
        end
      end

      let(:previous_school_mentor_at_school_periods) { [previous_period] }
      let(:previous_period) { FactoryBot.build_stubbed(:mentor_at_school_period, started_on: 2.months.ago) }

      let(:validator) { instance_double(Schools::Validation::PeriodBoundary) }

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

      context "when the date clashes with the previous school period" do
        let(:previous_period) do
          FactoryBot.create(:mentor_at_school_period,
                            school: previous_school,
                            started_on: Date.new(2024, 9, 1),
                            finished_on: Date.new(2025, 3, 31))
        end

        let(:start_date) { { 1 => "2024", 2 => "07", 3 => "01" } }

        before do
          allow(Schools::Validation::PeriodBoundary)
            .to receive(:new)
            .and_return(validator)

          allow(validator).to receive_messages(
            valid?: false,
            invalid_period: previous_period,
            type: "teaching",
            started_on_formatted: "1 September 2024",
            earliest_valid_input_date_formatted: "2 September 2024"
          )
        end

        it { is_expected.to have_error(:started_on, "Our records show that Johnnie Walker started teaching at Springfield Primary on 1 September 2024. Enter a start date after 2 September 2024.") }
      end

      context "when the date clashes with the latest training period" do
        let(:training_period) { FactoryBot.create(:training_period, :for_mentor, mentor_at_school_period: previous_period, started_on: Date.new(2024, 12, 31), finished_on: Date.new(2025, 3, 31)) }

        let(:previous_period) do
          FactoryBot.create(:mentor_at_school_period,
                            school: previous_school,
                            started_on: Date.new(2024, 9, 1),
                            finished_on: Date.new(2025, 3, 31))
        end

        let(:start_date) { { 1 => "2024", 2 => "12", 3 => "01" } }

        before do
          allow(Schools::Validation::PeriodBoundary)
            .to receive(:new)
            .and_return(validator)

          allow(validator).to receive_messages(
            valid?: false,
            invalid_period: training_period,
            type: "their latest training",
            started_on_formatted: "31 December 2024",
            earliest_valid_input_date_formatted: "1 January 2025"
          )
        end

        it { is_expected.to have_error(:started_on, "Our records show that Johnnie Walker started their latest training at Springfield Primary on 31 December 2024. Enter a start date after 1 January 2025.") }
      end

      context "when the date does not clash with any periods" do
        let(:start_date) { { 1 => "2024", 2 => "01", 3 => "01" } }

        before do
          allow(Schools::Validation::PeriodBoundary)
            .to receive(:new)
            .and_return(validator)

          allow(validator).to receive(:valid?).and_return(true)
        end

        it { is_expected.to be_valid }
      end
    end
  end
end
