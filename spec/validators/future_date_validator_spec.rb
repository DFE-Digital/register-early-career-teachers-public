RSpec.describe FutureDateValidator, type: :model do
  subject { model_class.new(declaration_date:) }

  let(:model_class) do
    Class.new do
      include ActiveModel::Model
      attr_accessor :declaration_date

      validates :declaration_date, future_date: true
    end
  end

  context "when date is nil" do
    let(:declaration_date) { nil }

    it "does not add an error" do
      expect(subject).to be_valid
      expect(subject.errors[:declaration_date]).to be_empty
    end
  end

  context "when date is valid" do
    let(:declaration_date) { Time.zone.yesterday }

    it "does not add an error" do
      expect(subject).to be_valid
      expect(subject.errors[:declaration_date]).to be_empty
    end
  end

  context "when date is invalid" do
    let(:declaration_date) { Time.zone.tomorrow }

    it "adds an error message" do
      expect(subject).to be_invalid
      expect(subject.errors[:declaration_date]).to include("The '#/declaration_date' value cannot be a future date. Check the date and try again.")
    end
  end
end
