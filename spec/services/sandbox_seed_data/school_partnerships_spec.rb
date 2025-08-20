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

      expect(SchoolPartnership.all.map(&:lead_provider).uniq).to eq(LeadProvider.all)
    end

    it "creates school partnerships for all contract periods" do
      instance.plant

      expect(SchoolPartnership.all.map(&:contract_period).uniq).to eq(ContractPeriod.all)
    end

    it "creates school partnership with same school but different delivery partner" do
      instance.plant

      count = SchoolPartnership.all.each_with_object({}) do |sp, sum|
        sum[sp.school_id] ||= []
        sum[sp.school_id] << sp.delivery_partner.id
      end

      expect(count.values.any? { |v| v.count > 1 }).to be(true)
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
        expect { instance.plant }.not_to change(ContractPeriod, :count)
      end
    end
  end
end
