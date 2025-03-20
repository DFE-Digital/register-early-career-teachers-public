RSpec.describe ECTStartDateValidator, type: :model do
  context "when date is in an invalid format" do
    subject { test_class.new(start_date:) }

    let(:start_date) { { 1 => "invalid year", 2 => "invalid month" } }
    let(:test_class) do
      Class.new do
        include ActiveModel::Model
        attr_accessor :start_date

        validates :start_date, ect_start_date: { current_date: Time.zone.today }
      end
    end

    it "adds an error" do
      subject.valid?
      expect(subject.errors[:start_date]).to include("Enter the start date using the correct format, for example 09 1999")
    end
  end

  context "when the current date is July 31st 2024" do
    subject { test_class.new(start_date:) }

    let(:error_message) { "The start date must be from within either the current academic year or one of the last 2 academic years" }
    let(:test_class) do
      Class.new do
        include ActiveModel::Model
        attr_accessor :start_date

        # Academic year begins in August 2023
        validates :start_date, ect_start_date: { current_date: Time.zone.local(2024, 7, 31) }
      end
    end

    context "and the start date is before the earlier possible start date" do
      # July 2021, ie more than 2 academic years ago
      let(:start_date) { { 1 => "2021", 2 => "07" } }

      it "adds an error" do
        subject.valid?
        expect(subject.errors[:start_date]).to include(error_message)
      end
    end

    context "and the start date is after the latest possible start date" do
      # August 2025, ie the next academic year
      let(:start_date) { { 1 => "2025", 2 => "08" } }

      it "adds an error" do
        subject.valid?
        expect(subject.errors[:start_date]).to include(error_message)
      end
    end

    context "and the start_date is within the accepted range" do
      let(:start_date) { { 1 => "2024", 2 => "07" } }

      it "does not add any errors" do
        subject.valid?
        expect(subject.errors[:start_date]).to be_empty
      end
    end
  end

  context "when the current date is August 1st 2024" do
    subject { test_class.new(start_date:) }

    let(:error_message) { "The start date must be from within either the current academic year or one of the last 2 academic years" }
    let(:test_class) do
      Class.new do
        include ActiveModel::Model
        attr_accessor :start_date

        # Academic year begins in August 2024
        validates :start_date, ect_start_date: { current_date: Time.zone.local(2024, 8, 1) }
      end
    end

    context "and the start date is before the earlier possible start date" do
      # July 2022, ie more than 2 academic years ago
      let(:start_date) { { 1 => "2022", 2 => "07" } }

      it "adds an error" do
        subject.valid?
        expect(subject.errors[:start_date]).to include(error_message)
      end
    end

    context "and the start date is after the latest possible start date" do
      # August 2026, ie the next academic year
      let(:start_date) { { 1 => "2026", 2 => "08" } }

      it "adds an error" do
        subject.valid?
        expect(subject.errors[:start_date]).to include(error_message)
      end
    end

    context "and the start_date is within the accepted range" do
      let(:start_date) { { 1 => "2025", 2 => "07" } }

      it "does not add any errors" do
        subject.valid?
        expect(subject.errors[:start_date]).to be_empty
      end
    end
  end

  context "when the start date is at the boundary of the accepted academic year range" do
    subject { test_class.new(start_date:) }

    let(:error_message) { "The start date must be from within either the current academic year or one of the last 2 academic years" }
    let(:test_class) do
      Class.new do
        include ActiveModel::Model
        attr_accessor :start_date

        validates :start_date, ect_start_date: { current_date: Time.zone.local(2024, 8, 1) }
      end
    end

    context "when the start date is the first month of the earliest academic year" do
      let(:start_date) { { 1 => "2022", 2 => "08" } }

      it "does not add any errors" do
        subject.valid?
        expect(subject.errors[:start_date]).to be_empty
      end
    end

    context "when the start date is the last month of the latest academic year" do
      let(:start_date) { { 1 => "2025", 2 => "07" } }

      it "does not add any errors" do
        subject.valid?
        expect(subject.errors[:start_date]).to be_empty
      end
    end
  end

  context "when the start date has invalid month or year values" do
    subject { test_class.new(start_date:) }

    let(:error_message) { "Enter the start date using the correct format, for example 09 1999" }
    let(:test_class) do
      Class.new do
        include ActiveModel::Model
        attr_accessor :start_date

        validates :start_date, ect_start_date: true
      end
    end

    context "when the month is outside the range 1-12" do
      let(:start_date) { { 1 => "2024", 2 => "13" } }

      it "adds an error" do
        subject.valid?
        expect(subject.errors[:start_date]).to include(error_message)
      end
    end

    context "when the year is non-integer" do
      # "abcd".to_i == 0 and and therefore a valid date year but it is out of range
      let(:start_date) { { 1 => "abcd", 2 => "07" } }
      let("error_message") { "The start date must be from within either the current academic year or one of the last 2 academic years" }

      it "adds an error" do
        subject.valid?
        expect(subject.errors[:start_date]).to include(error_message)
      end
    end

    context "when the month is non-integer" do
      let(:start_date) { { 1 => "2024", 2 => "abcd" } }

      it "adds an error" do
        subject.valid?
        expect(subject.errors[:start_date]).to include(error_message)
      end
    end
  end
end
