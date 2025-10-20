RSpec.describe API::Schools::Query, :with_metadata do
  before { FactoryBot.create(:lead_provider) } # Needed for metadata.

  it_behaves_like "a query that avoids includes" do
    let(:params) { {contract_period_year: FactoryBot.create(:contract_period).year} }

    before { FactoryBot.create(:school, :eligible) }
  end

  describe "preloading relationships" do
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

  describe "#schools" do
    subject(:query) { described_class.new(**query_params) }

    let(:query_params) do
      {
        contract_period_year:
      }
    end

    it "returns all eligible schools" do
      contract_period = FactoryBot.create(:contract_period)
      school = FactoryBot.create(:school, :eligible)

      expect(described_class.new(contract_period_year: contract_period.year).schools).to eq([school])
    end

    context "when there is existing partnerships" do
      let!(:contract_period) { FactoryBot.create(:contract_period) }
      let(:school1) { FactoryBot.create(:school, :eligible) }
      let(:school2) { FactoryBot.create(:school, :ineligible) }
      let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, contract_period:) }
      let!(:school1_partnership) { FactoryBot.create(:school_partnership, school: school1, lead_provider_delivery_partnership:) }
      let!(:school2_partnership) { FactoryBot.create(:school_partnership, school: school2, lead_provider_delivery_partnership:) }

      it "returns all schools" do
        expect(described_class.new(contract_period_year: contract_period.year).schools).to contain_exactly(school1, school2)
      end
    end

    it "orders schools by `created_at` date in ascending order" do
      contract_period = FactoryBot.create(:contract_period)
      school1 = FactoryBot.create(:school, :eligible, created_at: 2.days.ago)
      school2 = FactoryBot.create(:school, :eligible, created_at: 1.day.ago)
      school3 = FactoryBot.create(:school, :eligible, created_at: Time.zone.now)

      expect(described_class.new(contract_period_year: contract_period.year).schools).to contain_exactly(school1, school2, school3)
    end

    describe "filtering" do
      describe "by `contract_period_year`" do
        let!(:contract_period) { another_contract_period }
        let!(:school1) { FactoryBot.create(:school, :eligible) }
        let!(:school2) { FactoryBot.create(:school) }
        let!(:school3) { FactoryBot.create(:school) }
        let(:another_contract_period) { FactoryBot.create(:contract_period) }
        let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, contract_period: another_contract_period) }
        let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:) }
        let!(:school_partnership) { FactoryBot.create(:school_partnership, school: school3, lead_provider_delivery_partnership:) }
        let(:contract_period_year) { contract_period.year }

        let(:query_params) do
          {
            contract_period_year:
          }
        end

        it "includes ineligible schools with partnerships in the `contract_period_year`" do
          expect(query.schools).to contain_exactly(school1, school3)
        end

        context "when `contract_period_year` param is :ignore" do
          let(:contract_period_year) { :ignore }

          it "returns no schools (you must provide a contract period year)" do
            expect(query.schools).to be_empty
          end
        end

        context "when `contract_period_year` is not found" do
          let!(:contract_period_year) { "0000" }

          it "returns no schools" do
            expect(query.schools).to be_empty
          end
        end

        context "when `contract_period_year` param is blank" do
          let!(:contract_period_year) { " " }

          it "returns no schools" do
            expect(query.schools).to be_empty
          end
        end

        context "when `contract_period_year` param is nil" do
          let!(:contract_period_year) { nil }

          it "returns no schools" do
            expect(query.schools).to be_empty
          end
        end
      end

      describe "by `updated_since`" do
        let!(:contract_period) { training_period.contract_period }

        let!(:school1) { FactoryBot.create(:school, :eligible) }
        let!(:school2) { FactoryBot.create(:school, :eligible) }

        let!(:training_period) { FactoryBot.create(:training_period, :ongoing, :for_ect) }
        let!(:school3) { training_period.school_partnership.school }

        let(:updated_since) { 1.day.ago }

        let(:query_params) do
          {
            contract_period_year: contract_period.year,
            updated_since:
          }
        end

        before do
          school1.update!(api_updated_at: 2.days.ago)
          school2.update!(api_updated_at: 10.minutes.ago)
        end

        it "filters by `updated_since`" do
          expect(query.schools).to contain_exactly(school2, school3)
        end

        context "when `updated_since` param is omitted" do
          let(:query_params) do
            {
              contract_period_year: contract_period.year
            }
          end

          it "returns all eligible schools" do
            expect(query.schools).to contain_exactly(school1, school2, school3)
          end
        end

        context "when `contract_period_year` param is blank" do
          let!(:updated_since) { " " }

          it "returns all eligible schools" do
            expect(query.schools).to contain_exactly(school1, school2, school3)
          end
        end
      end

      describe "by `urn`" do
        let!(:contract_period) { FactoryBot.create(:contract_period) }
        let!(:school1) { FactoryBot.create(:school, :eligible, urn: "1234567") }
        let!(:school2) { FactoryBot.create(:school, :eligible, urn: "4567890") }
        let!(:urn) { school1.urn }

        let(:query_params) do
          {
            contract_period_year: contract_period.year,
            urn:
          }
        end

        it "filters by `urn`" do
          expect(query.schools).to contain_exactly(school1)
        end

        context "when `urn` param is omitted" do
          let(:query_params) do
            {
              contract_period_year: contract_period.year
            }
          end

          it "returns all eligible schools" do
            expect(query.schools).to contain_exactly(school1, school2)
          end
        end

        context "when `urn` param is blank" do
          let!(:urn) { " " }

          it "returns all eligible schools" do
            expect(query.schools).to contain_exactly(school1, school2)
          end
        end
      end
    end

    describe "sorting" do
      subject(:schools) { described_class.new(**query_params).schools }

      let!(:contract_period) { FactoryBot.create(:contract_period) }

      let(:school1) { FactoryBot.create(:school, :eligible, created_at: 1.day.ago) }
      let(:school2) { FactoryBot.create(:school, :eligible, created_at: 2.days.ago) }
      let(:school3) { FactoryBot.create(:school, :eligible, created_at: Time.zone.now) }

      let(:sort) { nil }

      let(:query_params) do
        {
          contract_period_year: contract_period.year,
          sort:
        }
      end

      it { is_expected.to eq([school2, school1, school3]) }

      context "when sorting by created at, descending" do
        let(:sort) { {created_at: :desc} }

        it { is_expected.to eq([school3, school1, school2]) }
      end

      context "when sorting by updated at, ascending" do
        let(:sort) { {updated_at: :asc} }

        before do
          school1.update!(updated_at: 1.day.from_now)
          school2.update!(updated_at: 2.days.from_now)
        end

        it { is_expected.to eq([school3, school1, school2]) }
      end

      context "when sorting by multiple attributes" do
        let(:sort) { {updated_at: :asc, created_at: :desc} }

        before do
          school1.update!(updated_at: 1.day.from_now)
          school2.update!(updated_at: school1.updated_at)
          school3.update!(updated_at: 2.days.from_now)

          school2.update!(created_at: 1.day.from_now)
          school1.update!(created_at: 1.day.ago)
        end

        it { expect(schools).to eq([school2, school1, school3]) }
      end
    end
  end

  describe "#school_by_api_id" do
    subject(:query) { described_class.new(**query_params) }

    let!(:contract_period) { FactoryBot.create(:contract_period) }
    let(:query_params) do
      {
        contract_period_year: contract_period.id
      }
    end

    let(:school) { FactoryBot.create(:school, :eligible) }

    it "returns a school for the given school api_id" do
      expect(query.school_by_api_id(school.api_id)).to eq(school)
    end

    it "raises an error if the school does not exist" do
      expect { query.school_by_api_id("XXX123") }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises an error if an api_id is not supplied" do
      expect { query.school_by_api_id(nil) }.to raise_error(ArgumentError, "api_id needed")
    end
  end

  describe "#school_by_id" do
    subject(:query) { described_class.new(**query_params) }

    let!(:contract_period) { FactoryBot.create(:contract_period) }
    let(:query_params) do
      {
        contract_period_year: contract_period.id
      }
    end

    let(:school) { FactoryBot.create(:school, :eligible) }

    it "returns a school for the given school id" do
      expect(query.school_by_id(school.id)).to eq(school)
    end

    it "raises an error if the school does not exist" do
      expect { query.school_by_id("XXX123") }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises an error if an id is not supplied" do
      expect { query.school_by_id(nil) }.to raise_error(ArgumentError, "id needed")
    end
  end
end
