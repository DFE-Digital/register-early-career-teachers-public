RSpec.describe APIDateTimeFormatValidator, type: :model do
  subject { model_class.new(date:) }

  let(:model_class) do
    Class.new do
      include ActiveModel::Model

      attr_accessor :date

      validates :date, api_date_time_format: true
    end
  end

  context "when date format is valid" do
    subject { model_class.new(date: "2021-06-21T08:46:29Z") }

    it "is valid" do
      expect(subject).to be_valid
    end
  end

  context "when the date is empty" do
    subject { model_class.new(date: "") }

    it "does not errors when the date is blank" do
      expect(subject).to be_valid
    end
  end

  context "when date format is invalid" do
    subject { model_class.new(date: "2021-06-21 08:46:29") }

    it "has a meaningful error" do
      expect(subject).to be_invalid
      expect(subject.errors.messages_for(:date)).to include("Enter a valid RCF3339 '#/date'.")
    end
  end

  context "when date is invalid" do
    subject { model_class.new(date: "2023-19-01T11:21:55Z") }

    it "has a meaningful error", :aggregate_failures do
      expect(subject).to be_invalid
      expect(subject.errors.messages_for(:date)).to include("Enter a valid RCF3339 '#/date'.")
    end
  end

  context "when time is invalid" do
    subject { model_class.new(date: "2023-19-01T29:21:55Z") }

    it "has a meaningful error", :aggregate_failures do
      expect(subject).to be_invalid
      expect(subject.errors.messages_for(:date)).to include("Enter a valid RCF3339 '#/date'.")
    end
  end
end
