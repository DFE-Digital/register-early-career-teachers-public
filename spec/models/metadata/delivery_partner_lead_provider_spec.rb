describe Metadata::DeliveryPartnerLeadProvider do
  include_context "restricts updates to the Metadata namespace", :delivery_partner_lead_provider_metadata

  describe "associations" do
    it { is_expected.to belong_to(:delivery_partner) }
    it { is_expected.to belong_to(:lead_provider) }
  end

  describe "validations" do
    subject { FactoryBot.create(:delivery_partner_lead_provider_metadata) }

    it { is_expected.to validate_presence_of(:delivery_partner) }
    it { is_expected.to validate_presence_of(:lead_provider) }
    it { is_expected.to allow_values((2021..Date.current.year).to_a).for(:contract_period_years) }
    it { is_expected.not_to allow_value(nil, false, 2022).for(:contract_period_years).with_message("must be an array") }
    it { is_expected.not_to allow_value([2020], [2019, 2022]).for(:contract_period_years).with_message("must contain valid years between 2021 and the current year") }
    it { is_expected.to validate_uniqueness_of(:delivery_partner_id).scoped_to(:lead_provider_id) }
  end
end
