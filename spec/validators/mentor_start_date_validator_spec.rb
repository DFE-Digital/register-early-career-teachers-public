RSpec.describe MentorStartDateValidator, type: :model do
  subject { test_class.new(start_date: start_date_hash) }

  let(:test_class) do
    Class.new do
      include ActiveModel::Model
      attr_accessor :start_date

      validates :start_date, mentor_start_date: true
    end
  end

  context "when date is in an invalid format" do
    let(:error_message) { "Enter the date in the correct format, for example 12 03 1998" }
    let(:start_date_hash) { { 1 => "invalid year", 2 => "invalid month", 3 => "invalid day" } }

    it { is_expected.to have_error(:start_date, error_message) }
  end

  context "when the start date has invalid values" do
    let(:error_message) { "Enter the date in the correct format, for example 12 03 1998" }

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
end
