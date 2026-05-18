RSpec.describe FlashHelper, type: :helper do
  describe "#flash_alert_heading" do
    context "when flash[:alert] is a string" do
      it "returns the string" do
        expect(helper.flash_alert_heading("Delivery partner added")).to eq("Delivery partner added")
      end
    end

    context "when flash[:alert] is a hash" do
      it "returns the heading value" do
        expect(helper.flash_alert_heading({ "heading" => "Delivery partner added", "body" => "You can now add lead providers working with them." })).to eq("Delivery partner added")
      end
    end
  end

  describe "#flash_alert_body" do
    context "when flash[:alert] is a string" do
      it "returns nil" do
        expect(helper.flash_alert_body("Delivery partner added")).to be_nil
      end
    end

    context "when flash[:alert] is a hash" do
      it "returns the body value" do
        expect(helper.flash_alert_body({ "heading" => "Delivery partner added", "body" => "You can now add lead providers working with them." })).to eq("You can now add lead providers working with them.")
      end
    end
  end
end
