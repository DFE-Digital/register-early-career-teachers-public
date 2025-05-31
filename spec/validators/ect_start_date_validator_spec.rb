RSpec.describe ECTStartDateValidator, type: :model do
  context "when date is in an invalid format" do
    subject { test_class.new(start_date:) }

    let(:start_date) { { 1 => "invalid year", 2 => "invalid month", 3 => 'invalid day' } }
    let(:test_class) do
      Class.new do
        include ActiveModel::Model
        attr_accessor :start_date

        validates :start_date, ect_start_date: { current_date: Time.zone.today }
      end
    end

    it "adds an error" do
      subject.valid?
      expect(subject.errors[:start_date]).to include("Enter the start date using the correct format, for example, 17 09 1999")
    end
  end

  context "when the start date has invalid values" do
    subject { test_class.new(start_date:) }

    let(:error_message) { "Enter the start date using the correct format, for example, 17 09 1999" }
    let(:test_class) do
      Class.new do
        include ActiveModel::Model
        attr_accessor :start_date

        validates :start_date, ect_start_date: true
      end
    end

    context "when the month is outside the range 1-12" do
      let(:start_date) { { 1 => "2024", 2 => "13", 3 => "1" } }

      it "adds an error" do
        subject.valid?
        expect(subject.errors[:start_date]).to include(error_message)
      end
    end

    context "when the year is non-integer" do
      # "abcd".to_i == 0 and and therefore a valid date year but it is not valid
      let(:start_date) { { 1 => "abcd", 2 => "07", 3 => "1" } }

      it "adds an error" do
        subject.valid?
        expect(subject.errors[:start_date]).to include(error_message)
      end
    end

    context "when the month is non-integer" do
      let(:start_date) { { 1 => "2024", 2 => "abcd", 3 => "1" } }

      it "adds an error" do
        subject.valid?
        expect(subject.errors[:start_date]).to include(error_message)
      end
    end

    context "when the day is not an integer" do
      let(:start_date) { { 1 => "2024", 2 => "07", 3 => "abcd" } }

      it "adds an error" do
        subject.valid?
        expect(subject.errors[:start_date]).to include(error_message)
      end
    end
  end
end
