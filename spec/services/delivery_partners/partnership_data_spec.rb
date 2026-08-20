describe DeliveryPartners::PartnershipData do
  subject { DeliveryPartners::PartnershipData.new(delivery_partner_1) }

  let(:lead_provider_1) { FactoryBot.create(:lead_provider, name: "ZZZ") }
  let(:lead_provider_2) { FactoryBot.create(:lead_provider, name: "AAA") }

  let!(:contract_period_2027) { FactoryBot.create(:contract_period, year: 2027) } # unused but should be present in output
  let(:contract_period_2026) { FactoryBot.create(:contract_period, year: 2026) }
  let(:contract_period_2025) { FactoryBot.create(:contract_period, year: 2025) }

  let(:delivery_partner_1) { FactoryBot.create(:delivery_partner) }
  let(:delivery_partner_2) { FactoryBot.create(:delivery_partner) }
  let(:delivery_partner_3) { FactoryBot.create(:delivery_partner) }

  before do
    framework_agreement_1 = FactoryBot.create(:framework_agreement, lead_provider: lead_provider_1, contract_period: contract_period_2025)
    framework_agreement_2 = FactoryBot.create(:framework_agreement, lead_provider: lead_provider_1, contract_period: contract_period_2026)
    framework_agreement_3 = FactoryBot.create(:framework_agreement, lead_provider: lead_provider_2, contract_period: contract_period_2025)
    framework_agreement_4 = FactoryBot.create(:framework_agreement, lead_provider: lead_provider_2, contract_period: contract_period_2026)

    # not included
    FactoryBot.create(:lead_provider_delivery_partnership, delivery_partner: delivery_partner_2, framework_agreement: framework_agreement_4)
    FactoryBot.create(:lead_provider_delivery_partnership, delivery_partner: delivery_partner_2, framework_agreement: framework_agreement_2)

    # 2025, lead_provider_1
    FactoryBot.create(:lead_provider_delivery_partnership, delivery_partner: delivery_partner_1, framework_agreement: framework_agreement_1)

    # 2025, lead_provider_2
    FactoryBot.create(:lead_provider_delivery_partnership, delivery_partner: delivery_partner_1, framework_agreement: framework_agreement_3)

    # 2026, lead_provider 2
    FactoryBot.create(:lead_provider_delivery_partnership, delivery_partner: delivery_partner_1, framework_agreement: framework_agreement_4)
  end

  describe "#partners_by_contract_period" do
    it "includes all contract periods (even ones with no partnership data) order chronologically" do
      expect(subject.partners_by_contract_period.keys).to eql([2027, 2026, 2025])
    end

    it "returns the lead providers partnered with the given delivery partner by registration period year" do
      expect(subject.partners_by_contract_period).to eq(
        {
          contract_period_2027.year => [],
          contract_period_2026.year => [lead_provider_2.name],
          contract_period_2025.year => [lead_provider_2.name, lead_provider_1.name],
        }
      )
    end

    it "orders the lead provider names alphabetically" do
      expect(subject.partners_by_contract_period.fetch(contract_period_2025.year)).to eql([lead_provider_2.name, lead_provider_1.name])
    end
  end
end
