RSpec.describe APIDateTimeFormatValidator, type: :model do
  subject { model_class.new(declaration_date:) }

  let(:model_class) do
    Class.new do
      include ActiveModel::Model

      attr_accessor :declaration_date

      validates :declaration_date, api_date_time_format: true
    end
  end

  describe "the declaration date has the right format" do
    context "when the declaration date is empty" do
      subject { model_class.new(declaration_date: "") }

      it "does not errors when the declaration date is blank" do
        expect(subject).to be_valid
      end
    end

    context "when declaration date format is invalid" do
      subject { model_class.new(declaration_date: "2021-06-21 08:46:29") }

      it "has a meaningful error" do
        expect(subject).to be_invalid
        expect(subject.errors.messages_for(:declaration_date)).to include("Enter a valid RCF3339 '#/declaration_date'.")
      end
    end

    context "when declaration date is invalid" do
      subject { model_class.new(declaration_date: "2023-19-01T11:21:55Z") }

      it "has a meaningful error", :aggregate_failures do
        expect(subject).to be_invalid
        expect(subject.errors.messages_for(:declaration_date)).to include("Enter a valid RCF3339 '#/declaration_date'.")
      end
    end

    context "when declaration time is invalid" do
      subject { model_class.new(declaration_date: "2023-19-01T29:21:55Z") }

      it "has a meaningful error", :aggregate_failures do
        expect(subject).to be_invalid
        expect(subject.errors.messages_for(:declaration_date)).to include("Enter a valid RCF3339 '#/declaration_date'.")
      end
    end
  end
end
