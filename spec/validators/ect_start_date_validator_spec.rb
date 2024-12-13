require 'rails_helper'

describe ECTStartDateValidator do
  let(:test_class) do
    Class.new do
      include ActiveModel::Model
      attr_accessor :start_date

      validates :start_date, ect_start_date: true
    end
  end

  subject { test_class.new(start_date:) }

  def academic_year_range
    today = Time.zone.today
    current_year_start = Date.new(today.year, 8, 1)

    {
      earliest_start: current_year_start.prev_year(2), # August of two years ago
      latest_end: (current_year_start + 1.year) - 1.day # July 31 of next year
    }
  end

  context "when start_date is invalid" do
    context "when the start date is missing" do
      let(:start_date) {}

      it "adds an error" do
        subject.valid?
        expect(subject.errors[:start_date]).to include("Start date cannot be blank")
      end
    end

    context "when date is in an invalid format" do
      let(:start_date) { { 1 => "invalid year", 2 => "invalid month" } }

      it "adds an error" do
        subject.valid?
        expect(subject.errors[:start_date]).to include("Enter the start date using the correct format, for example 03 1998")
      end
    end

    context "when the start date is before the earliest academic year" do
      let(:error_message) { "The start date must be from within either the current academic year or one of the last 2 academic years" }
      let(:start_date) { { 1 => (academic_year_range[:earliest_start].year - 1).to_s, 2 => "07" } }

      it "adds an error" do
        subject.valid?
        expect(subject.errors[:start_date]).to include(error_message)
      end
    end

    context "when the start date is after the current academic year" do
      let(:error_message) { "The start date must be from within either the current academic year or one of the last 2 academic years" }
      let(:start_date) { { 1 => (academic_year_range[:latest_end].year + 1).to_s, 2 => "08" } }

      it "adds an error" do
        subject.valid?
        expect(subject.errors[:start_date]).to include(error_message)
      end
    end
  end

  context "when the start_date is valid" do
    let(:start_date) { { 1 => (Time.zone.today.year).to_s, 2 => "09" } }

    it "does not add any errors" do
      subject.valid?
      expect(subject.errors[:start_date]).to be_empty
    end
  end
end
