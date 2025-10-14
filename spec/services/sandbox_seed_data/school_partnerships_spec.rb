RSpec.describe SandboxSeedData::SchoolPartnerships do
  let(:instance) { described_class.new }
  let(:environment) { "sandbox" }
  let(:logger) { instance_double(Logger, info: nil, "formatter=" => nil, "level=" => nil) }

  let(:contract_period) { FactoryBot.create(:contract_period) }

  before do
    allow(Logger).to receive(:new).with($stdout) { logger }
    allow(Rails).to receive(:env) { environment.inquiry }

    stub_const("#{described_class}::SCHOOL_PARTNERSHIPS_PER_ACTIVE_LEAD_PROVIDER", 2)
    stub_const("#{described_class}::SAME_SCHOOL_DIFFERENT_DELIVERY_PARTNER_PER_ACTIVE_LEAD_PROVIDER", 1)

    FactoryBot.create_list(:active_lead_provider, 2, contract_period:)
    ActiveLeadProvider.find_each do |active_lead_provider|
      FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:)
    end
    FactoryBot.create_list(:delivery_partner, 2)
    FactoryBot.create_list(:school, 2)
  end

  describe "#plant" do
    it "creates school partnerships for all lead providers" do
      instance.plant

      expect(SchoolPartnership.all.map(&:lead_provider).uniq).to match_array(LeadProvider.all)
    end

    it "creates school partnerships for all contract periods" do
      instance.plant

      expect(SchoolPartnership.all.map(&:contract_period).uniq).to match_array(ContractPeriod.all)
    end

    it "creates school partnership with same school but different delivery partner" do
      instance.plant

      schools_with_multiple_delivery_partners = SchoolPartnership
        .joins(:lead_provider_delivery_partnership)
        .group(:school_id)
        .having("COUNT(DISTINCT lead_provider_delivery_partnerships.delivery_partner_id) > 1")
        .pluck(:school_id)

      expect(schools_with_multiple_delivery_partners).to be_present
    end

    it "logs the creation of school partnerships" do
      instance.plant

      expect(logger).to have_received("level=").with(Logger::INFO)
      expect(logger).to have_received("formatter=").with(Rails.logger.formatter)

      expect(logger).to have_received(:info).with(/Planting school partnerships/).once

      school_partnership = SchoolPartnership.all.sample
      expect(logger).to have_received(:info).with(/#{school_partnership.school.urn}/).at_least(:once)
    end

    context "when in the production environment" do
      let(:environment) { "production" }

      it "does not create any school partnerships" do
        expect { instance.plant }.not_to change(SchoolPartnership, :count)
      end
    end
  end
end
