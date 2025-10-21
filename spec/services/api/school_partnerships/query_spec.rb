describe API::SchoolPartnerships::Query do
  it_behaves_like "a query that avoids includes" do
    before { FactoryBot.create(:school_partnership) }
  end

  describe "preloading relationships" do
    shared_examples "preloaded associations" do
      it { expect(result.association(:delivery_partner)).to be_loaded }
      it { expect(result.association(:active_lead_provider)).to be_loaded }
      it { expect(result.association(:school)).to be_loaded }
      it { expect(result.school.association(:gias_school)).to be_loaded }
    end

    let(:instance) { described_class.new }

    let!(:school_partnership) { FactoryBot.create(:school_partnership) }

    describe "#school_partnerships" do
      subject(:result) { instance.school_partnerships.first }

      include_context "preloaded associations"
    end

    describe "#school_partnership_by_api_id" do
      subject(:result) { instance.school_partnership_by_api_id(school_partnership.api_id) }

      include_context "preloaded associations"
    end

    describe "#school_partnership_by_id" do
      subject(:result) { instance.school_partnership_by_id(school_partnership.id) }

      include_context "preloaded associations"
    end
  end

  describe "#school_partnerships" do
    it "returns all school partnerships" do
      school_partnerships = FactoryBot.create_list(:school_partnership, 3)
      query = described_class.new

      expect(query.school_partnerships).to match_array(school_partnerships)
    end

    it "orders school partnerships by created_at in ascending order" do
      school_partnership1 = travel_to(2.days.ago) { FactoryBot.create(:school_partnership) }
      school_partnership2 = travel_to(1.day.ago) { FactoryBot.create(:school_partnership) }
      school_partnership3 = FactoryBot.create(:school_partnership)

      query = described_class.new

      expect(query.school_partnerships).to eq([school_partnership1, school_partnership2, school_partnership3])
    end

    describe "filtering" do
      describe "by `lead_provider`" do
        let(:lead_provider) { FactoryBot.create(:lead_provider) }
        let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:) }
        let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:) }
        let!(:school_partnership1) { FactoryBot.create(:school_partnership, lead_provider_delivery_partnership:) }
        let!(:school_partnership2) { FactoryBot.create(:school_partnership) }
        let!(:school_partnership3) { FactoryBot.create(:school_partnership) }

        context "when `lead_provider` param is omitted" do
          it "returns all school partnerships" do
            expect(described_class.new.school_partnerships).to contain_exactly(school_partnership1, school_partnership2, school_partnership3)
          end
        end

        it "filters by `lead_provider`" do
          lead_provider_id = lead_provider.id
          query = described_class.new(lead_provider_id:)

          expect(query.school_partnerships).to contain_exactly(school_partnership1)
        end

        it "returns empty if no school partnerships are found for the given `lead_provider`" do
          query = described_class.new(lead_provider_id: FactoryBot.create(:lead_provider).id)

          expect(query.school_partnerships).to be_empty
        end

        it "does not filter by `lead_provider` if an empty string is supplied" do
          query = described_class.new(lead_provider_id: " ")

          expect(query.school_partnerships).to contain_exactly(school_partnership1, school_partnership2, school_partnership3)
        end
      end

      describe "by `contract_period_years`" do
        let(:contract_period1) { FactoryBot.create(:contract_period) }
        let(:contract_period2) { FactoryBot.create(:contract_period) }
        let(:contract_period3) { FactoryBot.create(:contract_period) }
        let(:active_lead_provider1) { FactoryBot.create(:active_lead_provider, contract_period: contract_period1) }
        let(:active_lead_provider2) { FactoryBot.create(:active_lead_provider, contract_period: contract_period2) }
        let(:active_lead_provider3) { FactoryBot.create(:active_lead_provider, contract_period: contract_period3) }
        let(:lead_provider_delivery_partnership1) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider: active_lead_provider1) }
        let(:lead_provider_delivery_partnership2) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider: active_lead_provider2) }
        let(:lead_provider_delivery_partnership3) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider: active_lead_provider3) }
        let!(:school_partnership1) { FactoryBot.create(:school_partnership, lead_provider_delivery_partnership: lead_provider_delivery_partnership1) }
        let!(:school_partnership2) { FactoryBot.create(:school_partnership, lead_provider_delivery_partnership: lead_provider_delivery_partnership2) }
        let!(:school_partnership3) { FactoryBot.create(:school_partnership, lead_provider_delivery_partnership: lead_provider_delivery_partnership3) }

        context "when `contract_period_years` param is omitted" do
          it "returns all school partnerships" do
            expect(described_class.new.school_partnerships).to contain_exactly(school_partnership1, school_partnership2, school_partnership3)
          end
        end

        it "filters by `contract_period_years`" do
          query = described_class.new(contract_period_years: contract_period2.year.to_s)

          expect(query.school_partnerships).to eq([school_partnership2])
        end

        it "filters by multiple `contract_period_years`" do
          query1 = described_class.new(contract_period_years: [contract_period1.year, contract_period2.year])
          expect(query1.school_partnerships).to contain_exactly(school_partnership1, school_partnership2)

          query2 = described_class.new(contract_period_years: [contract_period2.year.to_s, contract_period3.year.to_s])
          expect(query2.school_partnerships).to contain_exactly(school_partnership2, school_partnership3)
        end

        it "returns no school partnerships if no `contract_period_years` are found" do
          query = described_class.new(contract_period_years: "0000")

          expect(query.school_partnerships).to be_empty
        end

        it "returns no school partnerships if `contract_period_years` is an empty array" do
          query = described_class.new(contract_period_years: [])

          expect(query.school_partnerships).to be_empty
        end

        it "ignores invalid `contract_period_years`" do
          query = described_class.new(contract_period_years: [contract_period1.year, 1099])

          expect(query.school_partnerships).to contain_exactly(school_partnership1)
        end

        it "does not filter by `contract_period_years` if blank" do
          query = described_class.new(contract_period_years: " ")

          expect(query.school_partnerships).to contain_exactly(school_partnership1, school_partnership2, school_partnership3)
        end
      end

      describe "by `updated_since`" do
        it "filters by `updated_since`" do
          FactoryBot.create(:school_partnership, api_updated_at: 2.days.ago)
          school_partnership2 = FactoryBot.create(:school_partnership, api_updated_at: Time.zone.now)

          query = described_class.new(updated_since: 1.day.ago)

          expect(query.school_partnerships).to eq([school_partnership2])
        end

        context "when `updated_since` param is omitted" do
          it "returns all statements" do
            school_partnership1 = FactoryBot.create(:school_partnership, api_updated_at: 1.week.ago)
            school_partnership2 = FactoryBot.create(:school_partnership, api_updated_at: 2.weeks.ago)

            expect(described_class.new.school_partnerships).to contain_exactly(school_partnership1, school_partnership2)
          end
        end

        it "does not filter by `updated_since` if blank" do
          school_partnership1 = FactoryBot.create(:school_partnership, api_updated_at: 1.week.ago)
          school_partnership2 = FactoryBot.create(:school_partnership, api_updated_at: 2.weeks.ago)

          query = described_class.new(updated_since: " ")

          expect(query.school_partnerships).to contain_exactly(school_partnership1, school_partnership2)
        end
      end

      describe "by `delivery_partner_api_ids`" do
        let!(:school_partnership1) { FactoryBot.create(:school_partnership) }
        let!(:school_partnership2) { FactoryBot.create(:school_partnership) }
        let!(:school_partnership3) { FactoryBot.create(:school_partnership) }

        context "when `delivery_partner_api_ids` param is omitted" do
          it "returns all school partnerships" do
            expect(described_class.new.school_partnerships).to contain_exactly(school_partnership1, school_partnership2, school_partnership3)
          end
        end

        it "filters by `delivery_partner_api_ids`" do
          query = described_class.new(delivery_partner_api_ids: school_partnership2.delivery_partner.api_id)

          expect(query.school_partnerships).to eq([school_partnership2])
        end

        it "filters by multiple `delivery_partner_api_ids`" do
          query1 = described_class.new(delivery_partner_api_ids: [school_partnership1.delivery_partner.api_id, school_partnership2.delivery_partner.api_id])
          expect(query1.school_partnerships).to contain_exactly(school_partnership1, school_partnership2)

          query2 = described_class.new(delivery_partner_api_ids: [school_partnership2.delivery_partner.api_id, school_partnership3.delivery_partner.api_id])
          expect(query2.school_partnerships).to contain_exactly(school_partnership2, school_partnership3)
        end

        it "returns no school partnerships if no `delivery_partner_api_ids` are found" do
          query = described_class.new(delivery_partner_api_ids: "0000")

          expect(query.school_partnerships).to be_empty
        end

        it "ignores invalid `delivery_partner_api_ids`" do
          query = described_class.new(delivery_partner_api_ids: [school_partnership1.delivery_partner.api_id, "invalid_api_id"])

          expect(query.school_partnerships).to contain_exactly(school_partnership1)
        end

        it "does not filter by `delivery_partner_api_ids` if blank" do
          query = described_class.new(delivery_partner_api_ids: " ")

          expect(query.school_partnerships).to contain_exactly(school_partnership1, school_partnership2, school_partnership3)
        end
      end
    end

    describe "ordering" do
      let!(:school_partnership1) { FactoryBot.create(:school_partnership) }
      let!(:school_partnership2) { travel_to(1.day.ago) { FactoryBot.create(:school_partnership) } }

      describe "default order" do
        it "returns school partnerships ordered by created_at, in ascending order" do
          query = described_class.new
          expect(query.school_partnerships).to eq([school_partnership2, school_partnership1])
        end
      end

      describe "order by created_at, in descending order" do
        it "returns school partnerships in correct order" do
          query = described_class.new(sort: { created_at: :desc })
          expect(query.school_partnerships).to eq([school_partnership1, school_partnership2])
        end
      end

      describe "order by updated_at, in ascending order" do
        it "returns school partnerships in correct order" do
          query = described_class.new(sort: { updated_at: :asc })
          expect(query.school_partnerships).to eq([school_partnership2, school_partnership1])
        end
      end

      describe "order by updated_at, in descending order" do
        it "returns school partnerships in correct order" do
          query = described_class.new(sort: { updated_at: :desc })
          expect(query.school_partnerships).to eq([school_partnership1, school_partnership2])
        end
      end
    end
  end

  describe "#school_partnership_by_api_id" do
    let(:lead_provider) { FactoryBot.create(:lead_provider) }

    it "returns the school partnership for a given id" do
      school_partnership = FactoryBot.create(:school_partnership)
      query = described_class.new

      expect(query.school_partnership_by_api_id(school_partnership.api_id)).to eq(school_partnership)
    end

    it "raises an error if the school partnership does not exist" do
      query = described_class.new

      expect { query.school_partnership_by_api_id("XXX123") }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises an error if the school partnership is not in the filtered query" do
      school_partnership1 = FactoryBot.create(:school_partnership)
      school_partnership2 = FactoryBot.create(:school_partnership)

      query = described_class.new(lead_provider_id: school_partnership1.lead_provider.id)

      expect { query.school_partnership_by_api_id(school_partnership2.api_id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises an error if an api_id is not supplied" do
      expect { described_class.new.school_partnership_by_api_id(nil) }.to raise_error(ArgumentError, "api_id needed")
    end
  end

  describe "#school_partnership_by_id" do
    it "returns the school partnership for a given id" do
      school_partnership = FactoryBot.create(:school_partnership)
      query = described_class.new

      expect(query.school_partnership_by_id(school_partnership.id)).to eq(school_partnership)
    end

    it "raises an error if the school partnership does not exist" do
      query = described_class.new

      expect { query.school_partnership_by_id("XXX123") }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises an error if the school partnership is not in the filtered query" do
      school_partnership1 = FactoryBot.create(:school_partnership)
      school_partnership2 = FactoryBot.create(:school_partnership)

      query = described_class.new(lead_provider_id: school_partnership1.lead_provider.id)

      expect { query.school_partnership_by_id(school_partnership2.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises an error if an id is not supplied" do
      expect { described_class.new.school_partnership_by_id(nil) }.to raise_error(ArgumentError, "id needed")
    end
  end

  describe '#exists?' do
    subject { described_class.new(**query_params) }

    let(:lead_provider) { FactoryBot.create(:lead_provider) }
    let!(:lead_provider_id) { lead_provider.id }
    let(:contract_period) { FactoryBot.create(:contract_period, year: 2027) }
    let!(:contract_period_years) { contract_period.year }
    let(:delivery_partner) { FactoryBot.create(:delivery_partner) }
    let!(:delivery_partner_api_ids) { delivery_partner.api_id }
    let(:school) { FactoryBot.create(:school) }
    let!(:school_id) { school.id }

    let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:, contract_period:) }
    let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:, delivery_partner:) }
    let!(:school_partnership) { FactoryBot.create(:school_partnership, lead_provider_delivery_partnership:, school:) }

    let(:query_params) { { lead_provider_id:, school_id:, delivery_partner_api_ids:, contract_period_years: } }

    it 'returns true when a school partnership matches lead provider, delivery partner and school for the given registration period' do
      expect(described_class.new(**query_params)).to exist
    end

    describe 'registration periods' do
      context 'when contract_period differs' do
        subject { described_class.new(**query_params.merge(contract_period_years: other_contract_period.year)) }

        let(:other_contract_period) { FactoryBot.create(:contract_period, year: 2028) }

        it { is_expected.not_to(exist) }
      end

      context 'when contract_period omitted' do
        subject { described_class.new(**query_params.except(:contract_period_years)) }

        it { is_expected.to(exist) }
      end
    end

    describe 'lead providers' do
      context 'when lead_provider differs' do
        subject { described_class.new(**query_params.merge(lead_provider_id: other_lead_provider.id)) }

        let(:other_lead_provider) { FactoryBot.create(:lead_provider) }

        it { is_expected.not_to(exist) }
      end

      context 'when lead_provider omitted' do
        subject { described_class.new(**query_params.except(:lead_provider_id)) }

        it { is_expected.to(exist) }
      end
    end

    describe 'schools' do
      context 'when school differs' do
        subject { described_class.new(**query_params.merge(school_id: other_school.id)) }

        let(:other_school) { FactoryBot.create(:school) }

        it { is_expected.not_to(exist) }
      end

      context 'when school omitted' do
        subject { described_class.new(**query_params.except(:school_id)) }

        it { is_expected.to(exist) }
      end
    end

    describe 'delivery partners' do
      context 'when delivery partner differs' do
        subject { described_class.new(**query_params.merge(delivery_partner_api_ids: other_delivery_partner.api_id)) }

        let(:other_delivery_partner) { FactoryBot.create(:delivery_partner) }

        it { is_expected.not_to(exist) }
      end

      context 'when delivery_partner omitted' do
        subject { described_class.new(**query_params.except(:delivery_partner_api_ids)) }

        it { is_expected.to(exist) }
      end
    end
  end
end
