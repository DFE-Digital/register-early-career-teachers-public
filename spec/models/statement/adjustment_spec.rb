describe Statement::Adjustment do
  describe "associations" do
    it { is_expected.to belong_to(:statement) }
  end

  describe "validations" do
    subject { create(:statement_adjustment) }

    it { is_expected.to validate_presence_of(:payment_type).with_message("Payment type is required") }
    it { is_expected.to validate_presence_of(:amount).with_message("Amount is required") }
    it { is_expected.to validate_numericality_of(:amount).is_other_than(0).with_message("Amount must be greater than 0") }
    it { is_expected.to validate_uniqueness_of(:api_id).case_insensitive.with_message("API id already exists for another statement adjustment") }

    it "returns validation error when amount is less than -1,000,000" do
      subject.amount = -1_000_001.0
      subject.valid?
      expect(subject.errors[:amount]).to include("Amount must be greater than or equal to -1,000,000")
    end

    it "returns validation error when amount is greater than 1,000,000" do
      subject.amount = 1_000_001.0
      subject.valid?
      expect(subject.errors[:amount]).to include("Amount must be less than or equal to 1,000,000")
    end
  end
end
