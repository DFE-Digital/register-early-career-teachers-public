RSpec.describe Notify::Outbound do
  subject(:outbound) { FactoryBot.build(:notify_outbound) }

  describe "db indexes" do
    it { is_expected.to have_db_index(:reference).unique(true) }
  end

  describe "associations" do
    it "defines a has_one association with delivery_receipt" do
      expect(outbound)
        .to have_one(:delivery_receipt)
        .class_name("Notify::DeliveryReceipt")
        .inverse_of(:notify_outbound)
        .dependent(:restrict_with_error)
    end
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:reference) }
    it { is_expected.to validate_uniqueness_of(:reference) }
    it { is_expected.to validate_presence_of(:mailer) }
    it { is_expected.to validate_presence_of(:mailer_action) }
  end
end
