describe API::SchoolSerializer, type: :serializer do
  subject(:response) do
    options = { contract_period_year: contract_period.year, lead_provider_id: lead_provider.id }
    JSON.parse(described_class.render(school, **options))
  end

  let(:lead_provider) { FactoryBot.create(:lead_provider) }
  let(:contract_period) { FactoryBot.create(:contract_period) }
  let(:school) { FactoryBot.create(:school, created_at:, api_updated_at:) }
  let!(:contract_period_metadata) { FactoryBot.create(:school_contract_period_metadata, school:, contract_period:) }
  let!(:lead_provider_contract_period_metadata) { FactoryBot.create(:school_lead_provider_contract_period_metadata, school:, lead_provider:, contract_period:) }
  let(:created_at) { Time.utc(2023, 7, 1, 12, 0, 0) }
  let(:api_updated_at) { Time.utc(2023, 7, 2, 12, 0, 0) }

  before do
    # Ensure other metadata exists.
    other_contract_period = FactoryBot.create(:contract_period, year: contract_period.year + 1)
    other_lead_provider = FactoryBot.create(:lead_provider)

    FactoryBot.create(:school_contract_period_metadata, school:, contract_period: other_contract_period)
    FactoryBot.create(:school_lead_provider_contract_period_metadata, school:, contract_period: other_contract_period, lead_provider: other_lead_provider)
  end

  describe "core attributes" do
    it "serializes correctly" do
      expect(response["id"]).to eq(school.api_id)
      expect(response["type"]).to eq("school")
    end
  end

  describe "nested attributes" do
    subject(:attributes) { response["attributes"] }

    it "serializes correctly" do
      expect(attributes["name"]).to eq(school.name)
      expect(attributes["urn"]).to eq(school.urn.to_s)
      expect(attributes["cohort"]).to eq(contract_period.year.to_s)
      expect(attributes["in_partnership"]).to eq(contract_period_metadata.in_partnership)
      expect(attributes["induction_programme_choice"]).to eq(contract_period_metadata.induction_programme_choice)
      expect(attributes["expression_of_interest"]).to eq(lead_provider_contract_period_metadata.expression_of_interest_or_school_partnership)
      expect(attributes["created_at"]).to eq(school.created_at.utc.rfc3339)
      expect(attributes["updated_at"]).to eq(school.api_updated_at.utc.rfc3339)
    end
  end
end
