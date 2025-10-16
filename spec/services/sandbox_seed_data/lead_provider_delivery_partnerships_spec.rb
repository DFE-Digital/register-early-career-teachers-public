RSpec.describe SandboxSeedData::LeadProviderDeliveryPartnerships do
  let(:instance) { described_class.new }
  let(:environment) { "sandbox" }
  let(:logger) { instance_double(Logger, :info => nil, "formatter=" => nil, "level=" => nil) }

  before do
    allow(Rails).to receive(:env) { environment.inquiry }
    allow(Logger).to receive(:new).with($stdout) { logger }

    FactoryBot.create_list(:delivery_partner, described_class::DELIVERY_PARTNERS_PER_LEAD_PROVIDER * 2)
  end

  describe "#plant" do
    let(:year) { described_class::APPLICABLE_CONTRACT_PERIOD_YEARS.sample }
    let(:contract_period) { FactoryBot.create(:contract_period, year:) }
    let!(:active_lead_provider) { FactoryBot.create(:active_lead_provider, contract_period:) }

    it "creates the correct number of lead provider delivery partnerships" do
      minimum_records = described_class::DELIVERY_PARTNERS_PER_LEAD_PROVIDER
      maximum_records = minimum_records + described_class::SHARED_DELIVERY_PARTNERS_PER_LEAD_PROVIDER
      expect { instance.plant }.to(change(LeadProviderDeliveryPartnership, :count).by(minimum_records..maximum_records))
    end

    it "creates lead provider delivery partnerships with the correct attributes" do
      instance.plant

      LeadProviderDeliveryPartnership.find_each do |partnership|
        expect(partnership).to have_attributes(
          active_lead_provider:,
          delivery_partner: be_present
        )
      end
    end

    it "logs the creation of lead provider delivery partnerships" do
      instance.plant

      expect(logger).to have_received("level=").with(Logger::INFO)
      expect(logger).to have_received("formatter=").with(Rails.logger.formatter)

      expect(logger).to have_received(:info).with(/Planting lead provider delivery partnerships/).once

      LeadProvider.find_each do |lead_provider|
        expect(logger).to have_received(:info).with(/#{lead_provider.name}/).once
      end

      expect(logger).to have_received(:info).with(/Shared delivery partners/).once
    end

    context "when there are multiple active lead providers" do
      let!(:another_active_lead_provider) { FactoryBot.create(:active_lead_provider, contract_period:) }

      it "creates shared delivery partners between lead providers" do
        instance.plant

        delivery_partner_ids_1 = active_lead_provider.lead_provider_delivery_partnerships.pluck(:delivery_partner_id)
        delivery_partner_ids_2 = another_active_lead_provider.lead_provider_delivery_partnerships.pluck(:delivery_partner_id)

        overlapping_ids = delivery_partner_ids_1 & delivery_partner_ids_2
        expect(overlapping_ids.size).to be >= described_class::SHARED_DELIVERY_PARTNERS_PER_LEAD_PROVIDER
      end
    end

    context "when in the production environment" do
      let(:environment) { "production" }

      it "does not create any delivery partners" do
        expect { instance.plant }.not_to change(LeadProviderDeliveryPartnership, :count)
      end
    end
  end
end
