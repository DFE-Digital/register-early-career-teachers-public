describe SchoolPartnerships::Search do
  describe "#school_partnerships" do
    it "returns all school parnerships partners" do
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
          query = described_class.new(lead_provider:)

          expect(query.school_partnerships).to contain_exactly(school_partnership1)
        end

        it "filters by `lead_provider.id`" do
          query = described_class.new(lead_provider: lead_provider.id)

          expect(query.school_partnerships).to contain_exactly(school_partnership1)
        end

        it "returns empty if no school partnerships are found for the given `lead_provider`" do
          query = described_class.new(lead_provider: FactoryBot.create(:lead_provider))

          expect(query.school_partnerships).to be_empty
        end

        it "does not filter by `lead_provider` if an empty string is supplied" do
          query = described_class.new(lead_provider: " ")

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

        it "filters by `contract_period`" do
          query = described_class.new(contract_period: contract_period2)

          expect(query.school_partnerships).to eq([school_partnership2])
        end

        it "filters by `contract_period.year`" do
          query = described_class.new(contract_period: contract_period2.year)

          expect(query.school_partnerships).to eq([school_partnership2])
        end

        it "filters by `contract_period.year.to_s`" do
          query = described_class.new(contract_period: contract_period2.year.to_s)

          expect(query.school_partnerships).to eq([school_partnership2])
        end

        it "filters by multiple `contract_period`" do
          query1 = described_class.new(contract_period: [contract_period1, contract_period2])
          expect(query1.school_partnerships).to contain_exactly(school_partnership1, school_partnership2)

          query2 = described_class.new(contract_period: [contract_period2, contract_period3])
          expect(query2.school_partnerships).to contain_exactly(school_partnership2, school_partnership3)
        end

        it "returns no school partnerships if no `contract_period` are found" do
          query = described_class.new(contract_period: "0000")

          expect(query.school_partnerships).to be_empty
        end

        it "ignores invalid `contract_period`" do
          query = described_class.new(contract_period: "#{contract_period1.year},invalid_year")

          expect(query.school_partnerships).to contain_exactly(school_partnership1)
        end

        it "does not filter by `contract_period_years` if blank" do
          query = described_class.new(contract_period: " ")

          expect(query.school_partnerships).to contain_exactly(school_partnership1, school_partnership2, school_partnership3)
        end
      end

      describe "by `updated_since`" do
        it "filters by `updated_since`" do
          FactoryBot.create(:school_partnership, updated_at: 2.days.ago)
          school_partnership2 = FactoryBot.create(:school_partnership, updated_at: Time.zone.now)

          query = described_class.new(updated_since: 1.day.ago)

          expect(query.school_partnerships).to eq([school_partnership2])
        end

        context "when `updated_since` param is omitted" do
          it "returns all statements" do
            school_partnership1 = FactoryBot.create(:school_partnership, updated_at: 1.week.ago)
            school_partnership2 = FactoryBot.create(:school_partnership, updated_at: 2.weeks.ago)

            expect(described_class.new.school_partnerships).to contain_exactly(school_partnership1, school_partnership2)
          end
        end

        it "does not filter by `updated_since` if blank" do
          school_partnership1 = FactoryBot.create(:school_partnership, updated_at: 1.week.ago)
          school_partnership2 = FactoryBot.create(:school_partnership, updated_at: 2.weeks.ago)

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

        it "filters by `delivery_partner`" do
          query = described_class.new(delivery_partner: school_partnership2.delivery_partner)

          expect(query.school_partnerships).to eq([school_partnership2])
        end

        it "filters by multiple `delivery_partners`" do
          query = described_class.new(delivery_partner: [school_partnership1.delivery_partner, school_partnership2.delivery_partner])

          expect(query.school_partnerships).to eq([school_partnership1, school_partnership2])
        end

        it "filters by `delivery_partner_api_ids`" do
          query = described_class.new(delivery_partner_api_ids: school_partnership2.delivery_partner.api_id)

          expect(query.school_partnerships).to eq([school_partnership2])
        end

        it "filters by multiple `delivery_partner_api_ids`" do
          query1 = described_class.new(delivery_partner_api_ids: "#{school_partnership1.delivery_partner.api_id},#{school_partnership2.delivery_partner.api_id}")
          expect(query1.school_partnerships).to contain_exactly(school_partnership1, school_partnership2)

          query2 = described_class.new(delivery_partner_api_ids: [school_partnership2.delivery_partner.api_id, school_partnership3.delivery_partner.api_id])
          expect(query2.school_partnerships).to contain_exactly(school_partnership2, school_partnership3)
        end

        it "returns no school partnerships if no `delivery_partner_api_ids` are found" do
          query = described_class.new(delivery_partner_api_ids: "0000")

          expect(query.school_partnerships).to be_empty
        end

        it "ignores invalid `delivery_partner_api_ids`" do
          query = described_class.new(delivery_partner_api_ids: "#{school_partnership1.delivery_partner.api_id},invalid_api_id")

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
          query = described_class.new(sort: "-created_at")
          expect(query.school_partnerships).to eq([school_partnership1, school_partnership2])
        end
      end

      describe "order by updated_at, in ascending order" do
        it "returns school partnerships in correct order" do
          query = described_class.new(sort: "+updated_at")
          expect(query.school_partnerships).to eq([school_partnership2, school_partnership1])
        end
      end

      describe "order by updated_at, in descending order" do
        it "returns school partnerships in correct order" do
          query = described_class.new(sort: "-updated_at")
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

      query = described_class.new(lead_provider: school_partnership1.lead_provider)

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

      query = described_class.new(lead_provider: school_partnership1.lead_provider)

      expect { query.school_partnership_by_id(school_partnership2.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises an error if an id is not supplied" do
      expect { described_class.new.school_partnership_by_id(nil) }.to raise_error(ArgumentError, "id needed")
    end
  end

  describe '#exists?' do
    subject { SchoolPartnerships::Search.new(**query_params) }

    let(:lead_provider) { FactoryBot.create(:lead_provider) }
    let(:contract_period) { FactoryBot.create(:contract_period, year: 2027) }
    let(:delivery_partner) { FactoryBot.create(:delivery_partner) }
    let!(:delivery_partner_api_ids) { delivery_partner.api_id }
    let(:school) { FactoryBot.create(:school) }

    let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:, contract_period:) }
    let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:, delivery_partner:) }
    let!(:school_partnership) { FactoryBot.create(:school_partnership, lead_provider_delivery_partnership:, school:) }

    let(:query_params) { { lead_provider:, school:, delivery_partner_api_ids:, contract_period: } }

    it 'returns true when a school partnership matches lead provider, delivery partner API ID and school for the given registration period' do
      expect(SchoolPartnerships::Search.new(lead_provider:, school:, contract_period:, delivery_partner_api_ids:)).to exist
    end

    describe 'registration periods' do
      context 'when contract_period differs' do
        subject { SchoolPartnerships::Search.new(**query_params.merge(contract_period: other_contract_period)) }

        let(:other_contract_period) { FactoryBot.create(:contract_period, year: 2028) }

        it { is_expected.not_to(exist) }
      end

      context 'when contract_period omitted' do
        subject { SchoolPartnerships::Search.new(**query_params.except(:contract_period_years)) }

        it { is_expected.to(exist) }
      end
    end

    describe 'lead providers' do
      context 'when lead_provider differs' do
        subject { SchoolPartnerships::Search.new(**query_params.merge(lead_provider: other_lead_provider)) }

        let(:other_lead_provider) { FactoryBot.create(:lead_provider) }

        it { is_expected.not_to(exist) }
      end

      context 'when lead_provider omitted' do
        subject { SchoolPartnerships::Search.new(**query_params.except(:lead_provider_id)) }

        it { is_expected.to(exist) }
      end
    end

    describe 'schools' do
      context 'when school differs' do
        subject { SchoolPartnerships::Search.new(**query_params.merge(school: other_school)) }

        let(:other_school) { FactoryBot.create(:school) }

        it { is_expected.not_to(exist) }
      end

      context 'when school omitted' do
        subject { SchoolPartnerships::Search.new(**query_params.except(:school)) }

        it { is_expected.to(exist) }
      end
    end

    describe 'delivery partners' do
      context 'when delivery partner differs' do
        subject { SchoolPartnerships::Search.new(**query_params.merge(delivery_partner_api_ids: other_delivery_partner.api_id)) }

        let(:other_delivery_partner) { FactoryBot.create(:delivery_partner) }

        it { is_expected.not_to(exist) }
      end

      context 'when delivery_partner omitted' do
        subject { SchoolPartnerships::Search.new(**query_params.except(:delivery_partner_api_ids)) }

        it { is_expected.to(exist) }
      end
    end
  end
end
