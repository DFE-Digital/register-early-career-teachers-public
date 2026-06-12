RSpec.describe ECTStartDateValidator, type: :model do
  subject { test_class.new(start_date: start_date_hash) }

  let(:test_class) do
    Class.new do
      include ActiveModel::Model

      attr_accessor :start_date

      validates :start_date, ect_start_date: true
    end
  end

  context "when date is in an invalid format" do
    let(:error_message) { "Enter the start date using the correct format, for example, 17 09 1999" }
    let(:start_date_hash) { { 1 => "invalid year", 2 => "invalid month", 3 => "invalid day" } }

    it { is_expected.to have_error(:start_date, error_message) }
  end

  context "when the start date has invalid values" do
    let(:error_message) { "Enter the start date using the correct format, for example, 17 09 1999" }

    context "when the month is outside the range 1-12" do
      let(:start_date_hash) { { 1 => "2024", 2 => "13", 3 => "1" } }

      it { is_expected.to have_error(:start_date, error_message) }
    end

    context "when the year is non-integer" do
      # "abcd".to_i == 0 and and therefore a valid date year but it is not valid
      let(:start_date_hash) { { 1 => "abcd", 2 => "07", 3 => "1" } }

      it { is_expected.to have_error(:start_date, error_message) }
    end

    context "when the month is non-integer" do
      let(:start_date_hash) { { 1 => "2024", 2 => "abcd", 3 => "1" } }

      it { is_expected.to have_error(:start_date, error_message) }
    end

    context "when the day is not an integer" do
      let(:start_date_hash) { { 1 => "2024", 2 => "07", 3 => "abcd" } }

      it { is_expected.to have_error(:start_date, error_message) }
    end
  end

  context "when the start date is earlier than the earliest permitted date" do
    let!(:current_contract_period) do
      FactoryBot.create(:contract_period, :current)
    end
    let!(:previous_contract_period) do
      FactoryBot.create(:contract_period, :previous)
    end
    let!(:earliest_permitted_contract_period) do
      FactoryBot.create(:contract_period, year: previous_contract_period.year - 1)
    end

    let(:error_message) { "Start date cannot be this far in the past. Enter a date later than #{earliest_permitted_contract_period.started_on.to_fs(:govuk)}." }
    let(:start_date) { earliest_permitted_contract_period.started_on.prev_day }
    let(:start_date_hash) { { 1 => start_date.year, 2 => start_date.month, 3 => start_date.day } }

    it { is_expected.to have_error(:start_date, error_message) }
  end
end
