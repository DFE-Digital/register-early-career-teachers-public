RSpec.describe Notify::DeliveryReceipt do
  subject(:delivery_receipt) { FactoryBot.build(:notify_delivery_receipt) }

  describe "enums" do
    it "defines status enum" do
      expect(delivery_receipt)
        .to define_enum_for(:status)
        .with_values({
          delivered: "delivered",
          permanent_failure: "permanent-failure",
          temporary_failure: "temporary-failure",
          technical_failure: "technical-failure"
        })
        .validating
        .with_prefix
        .backed_by_column_of_type(:enum)
    end

    it "defines notification_type enum" do
      expect(delivery_receipt)
        .to define_enum_for(:notification_type)
        .with_values({
          email: "email",
          sms: "sms"
        })
        .validating
        .with_prefix
        .backed_by_column_of_type(:enum)
    end
  end

  describe "db indexes" do
    it { is_expected.to have_db_index(:notification_id).unique(true) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:recipient) }
    it { is_expected.to validate_presence_of(:notification_id) }
    it { is_expected.to validate_uniqueness_of(:notification_id).case_insensitive }
    it { is_expected.to validate_presence_of(:requested_at) }
    it { is_expected.to validate_presence_of(:template_id) }
    it { is_expected.to validate_numericality_of(:template_version).is_greater_than(0).only_integer }

    context "when notification_type is email" do
      subject(:delivery_receipt) do
        FactoryBot.build(:notify_delivery_receipt, notification_type: "email")
      end

      it { is_expected.to be_valid }

      context "and recipient is not a valid email address" do
        subject(:delivery_receipt) do
          FactoryBot.build(
            :notify_delivery_receipt,
            notification_type: "email",
            recipient: "invalid-email"
          )
        end

        it { is_expected.to have_error(:recipient, "Enter an email address in the correct format, like name@example.com") }
      end
    end

    context "when notification_type is sms" do
      subject(:delivery_receipt) do
        FactoryBot.build(:notify_delivery_receipt, notification_type: "sms")
      end

      it { is_expected.to have_error(:notification_type, "Only email notification types are supported") }
    end

    context "when notification_type is something else" do
      subject(:delivery_receipt) do
        FactoryBot.build(:notify_delivery_receipt, notification_type: "push")
      end

      it { is_expected.to have_error(:notification_type, "Only email notification types are supported") }
    end
  end
end
