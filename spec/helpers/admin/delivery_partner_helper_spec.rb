RSpec.describe Admin::DeliveryPartnerHelper, type: :helper do
  describe "#delivery_partner_title" do
    let(:delivery_partner) { FactoryBot.create(:delivery_partner, name: "Alpha") }

    it "uses the persisted name when present" do
      expect(helper.delivery_partner_title(delivery_partner))
        .to eq("Change delivery partner name for Alpha")
    end

    it "normalises whitespace from the persisted name (squish)" do
      delivery_partner.update_column(:name, "  New   Name  ")
      expect(helper.delivery_partner_title(delivery_partner))
        .to eq("Change delivery partner name for New Name")
    end

    it "shows the base title when the persisted name is blank" do
      delivery_partner.update_column(:name, "")
      expect(helper.delivery_partner_title(delivery_partner))
        .to eq("Change delivery partner name")
    end

    it "ignores unsaved in-memory edits after a validation error" do
      delivery_partner.name = "Temporary"
      expect(helper.delivery_partner_title(delivery_partner))
        .to eq("Change delivery partner name for Alpha")
    end
  end
end
