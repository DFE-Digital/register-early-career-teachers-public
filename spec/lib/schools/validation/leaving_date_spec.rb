RSpec.describe Schools::Validation::LeavingDate do
  subject(:validator) { described_class.new(date_as_hash:) }

  describe "#valid?" do
    context "when date is empty" do
      let(:date_as_hash) { nil }

      it "is invalid with the missing message" do
        expect(validator).not_to be_valid
        expect(validator.error_message).to eq("Enter the date the teacher left or will be leaving your school")
      end
    end

    context "when date is more than 4 months in the future" do
      let(:date_as_hash) { { 1 => 2025, 2 => 5, 3 => 2 } }

      around do |example|
        travel_to(Date.new(2025, 1, 1)) { example.run }
      end

      it "is invalid with the future limit message" do
        expect(validator).not_to be_valid
        expect(validator.error_message).to eq("Enter a date no further than 4 months from today")
      end
    end

    context "when date is exactly 4 months in the future" do
      let(:date_as_hash) { { 1 => 2025, 2 => 5, 3 => 1 } }

      around do |example|
        travel_to(Date.new(2025, 1, 1)) { example.run }
      end

      it "is valid" do
        expect(validator).to be_valid
        expect(validator.error_message).to be_blank
      end
    end

    context "when date is today" do
      let(:today) { Date.new(2025, 1, 1) }
      let(:date_as_hash) { { 1 => today.year, 2 => today.month, 3 => today.day } }

      around do |example|
        travel_to(today) { example.run }
      end

      it "is valid" do
        expect(validator).to be_valid
        expect(validator.error_message).to be_blank
      end
    end
  end
end
