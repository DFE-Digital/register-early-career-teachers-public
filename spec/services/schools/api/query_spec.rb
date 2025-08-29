RSpec.describe Schools::API::Query do
  shared_examples "preloaded associations" do
    it { expect(result.association(:gias_school)).to be_loaded }
    it { expect(result.association(:contract_period_metadata)).to be_loaded }
    it { expect(result.association(:lead_provider_contract_period_metadata)).to be_loaded }

    context "when a lead_provider_id is specified" do
      let(:lead_provider_id) { lead_provider.id }

      it "only contains relevant metadata" do
        expect(result.lead_provider_contract_period_metadata).to contain_exactly(lead_provider_contract_period_metadata)
      end
    end

    context "when a contract_period_year is specified" do
      let(:contract_period_year) { contract_period.year }

      it "only contains relevant metadata" do
        expect(result.lead_provider_contract_period_metadata).to contain_exactly(lead_provider_contract_period_metadata)
        expect(result.contract_period_metadata).to contain_exactly(contract_period_metadata)
      end
    end
  end

  describe "preloading relationships" do
    let(:lead_provider_id) { :ignore }
    let(:contract_period_year) { contract_period.year }
    let(:instance) { described_class.new(lead_provider_id:, contract_period_year:) }

    let!(:school) { FactoryBot.create(:school, :eligible) }
    let(:lead_provider) { FactoryBot.create(:lead_provider) }
    let(:contract_period) { FactoryBot.create(:contract_period) }
    let!(:contract_period_metadata) { FactoryBot.create(:school_contract_period_metadata, school:, contract_period:) }
    let!(:lead_provider_contract_period_metadata) { FactoryBot.create(:school_lead_provider_contract_period_metadata, school:, lead_provider:, contract_period:) }

    before do
      # Ensure other metadata exists.
      other_contract_period = FactoryBot.create(:contract_period, year: contract_period.year + 1)
      other_lead_provider = FactoryBot.create(:lead_provider)

      FactoryBot.create(:school_contract_period_metadata, school:, contract_period: other_contract_period)
      FactoryBot.create(:school_lead_provider_contract_period_metadata, school:, contract_period: other_contract_period, lead_provider: other_lead_provider)
    end

    describe "#schools" do
      subject(:result) { instance.schools.first }

      include_context "preloaded associations"
    end

    describe "#school_by_api_id" do
      subject(:result) { instance.school_by_api_id(school.api_id) }

      include_context "preloaded associations"
    end

    describe "#school_by_id" do
      subject(:result) { instance.school_by_id(school.id) }

      include_context "preloaded associations"
    end
  end
end
