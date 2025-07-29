RSpec.describe DeliveryPartners::Query do
  describe "#delivery_partners" do
    it "returns all delivery partners" do
      delivery_partners = FactoryBot.create_list(:delivery_partner, 3)
      query = described_class.new

      expect(query.delivery_partners).to match_array(delivery_partners)
    end

    it "orders delivery partners by created_at in ascending order" do
      delivery_partner1 = travel_to(2.days.ago) { FactoryBot.create(:delivery_partner) }
      delivery_partner2 = travel_to(1.day.ago) { FactoryBot.create(:delivery_partner) }
      delivery_partner3 = FactoryBot.create(:delivery_partner)

      query = described_class.new

      expect(query.delivery_partners).to eq([delivery_partner1, delivery_partner2, delivery_partner3])
    end

    describe "transient_cohort" do
      let(:lead_provider_2024) { FactoryBot.create(:lead_provider) }
      let(:lead_provider_2025) { FactoryBot.create(:lead_provider) }

      let(:contract_period_2024) { FactoryBot.create(:contract_period, year: 2024) }
      let(:contract_period_2025) { FactoryBot.create(:contract_period, year: 2025) }

      let(:active_lead_provider_2024) { FactoryBot.create(:active_lead_provider, lead_provider: lead_provider_2024, contract_period: contract_period_2024) }
      let(:active_lead_provider_2025) { FactoryBot.create(:active_lead_provider, lead_provider: lead_provider_2025, contract_period: contract_period_2025) }

      let(:lead_provider_delivery_partnership_2024) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider: active_lead_provider_2024) }
      let!(:delivery_partner1) { lead_provider_delivery_partnership_2024.delivery_partner }
      let!(:lead_provider_delivery_partnership_2025) { FactoryBot.create(:lead_provider_delivery_partnership, delivery_partner: delivery_partner1, active_lead_provider: active_lead_provider_2025) }

      context "when ignoring lead provider" do
        let(:lead_provider) { :ignore }

        it "loads the cohorts for all lead providers" do
          query = described_class.new(lead_provider:)

          expect(query.delivery_partners).to contain_exactly(delivery_partner1)
          expect(query.delivery_partners.map(&:transient_cohort)).to contain_exactly(%w[2024 2025])
        end
      end

      context "when filter by lead provider" do
        let(:lead_provider) { lead_provider_2024 }

        it "only includes cohorts for the given lead provider" do
          query = described_class.new(lead_provider:)

          expect(query.delivery_partners).to contain_exactly(delivery_partner1)
          expect(query.delivery_partners.map(&:transient_cohort)).to contain_exactly(%w[2024])
        end
      end
    end

    describe "filtering" do
      describe "by `lead_provider`" do
        let(:lead_provider_delivery_partnership1) { FactoryBot.create(:lead_provider_delivery_partnership) }
        let!(:delivery_partner1) { lead_provider_delivery_partnership1.delivery_partner }
        let!(:delivery_partner2) { FactoryBot.create(:lead_provider_delivery_partnership).delivery_partner }
        let!(:delivery_partner3) { FactoryBot.create(:lead_provider_delivery_partnership).delivery_partner }

        context "when `lead_provider` param is omitted" do
          it "returns all delivery partners" do
            expect(described_class.new.delivery_partners).to contain_exactly(delivery_partner1, delivery_partner2, delivery_partner3)
          end
        end

        it "filters by `lead_provider`" do
          lead_provider = lead_provider_delivery_partnership1.active_lead_provider.lead_provider
          query = described_class.new(lead_provider:)

          expect(query.delivery_partners).to contain_exactly(delivery_partner1)
        end

        it "returns empty if no delivery partners are found for the given `lead_provider`" do
          query = described_class.new(lead_provider: FactoryBot.create(:lead_provider))

          expect(query.delivery_partners).to be_empty
        end

        it "does not filter by `lead_provider` if an empty string is supplied" do
          query = described_class.new(lead_provider: " ")

          expect(query.delivery_partners).to contain_exactly(delivery_partner1, delivery_partner2, delivery_partner3)
        end
      end

      describe "by `contract_period_years`" do
        let!(:contract_period1) { FactoryBot.create(:contract_period) }
        let!(:contract_period2) { FactoryBot.create(:contract_period) }
        let!(:contract_period3) { FactoryBot.create(:contract_period) }
        let!(:active_lead_provider1) { FactoryBot.create(:active_lead_provider, contract_period: contract_period1) }
        let!(:active_lead_provider2) { FactoryBot.create(:active_lead_provider, contract_period: contract_period2) }
        let!(:active_lead_provider3) { FactoryBot.create(:active_lead_provider, contract_period: contract_period3) }

        context "when `contract_period_years` param is omitted" do
          it "returns all delivery partners" do
            delivery_partner1 = FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider: active_lead_provider1).delivery_partner
            delivery_partner2 = FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider: active_lead_provider2).delivery_partner
            delivery_partner3 = FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider: active_lead_provider3).delivery_partner

            expect(described_class.new.delivery_partners).to contain_exactly(delivery_partner1, delivery_partner2, delivery_partner3)
          end
        end

        it "filters by `contract_period_years`" do
          FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider: active_lead_provider1)
          delivery_partner2 = FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider: active_lead_provider2).delivery_partner
          query = described_class.new(contract_period_years: contract_period2.year)

          expect(query.delivery_partners).to eq([delivery_partner2])
        end

        it "filters by multiple `contract_period_years`" do
          delivery_partner1 = FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider: active_lead_provider1).delivery_partner
          delivery_partner2 = FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider: active_lead_provider2).delivery_partner
          delivery_partner3 = FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider: active_lead_provider3).delivery_partner

          query1 = described_class.new(contract_period_years: "#{contract_period1.year},#{contract_period2.year}")
          expect(query1.delivery_partners).to contain_exactly(delivery_partner1, delivery_partner2)

          query2 = described_class.new(contract_period_years: [contract_period2.year.to_s, contract_period3.year.to_s])
          expect(query2.delivery_partners).to contain_exactly(delivery_partner2, delivery_partner3)
        end

        it "returns no delivery partners if no `contract_period_years` are found" do
          query = described_class.new(contract_period_years: "0000")

          expect(query.delivery_partners).to be_empty
        end

        it "does not filter by `contract_period_years` if blank" do
          delivery_partner1 = FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider: active_lead_provider1).delivery_partner
          delivery_partner2 = FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider: active_lead_provider2).delivery_partner

          query = described_class.new(contract_period_years: " ")

          expect(query.delivery_partners).to contain_exactly(delivery_partner1, delivery_partner2)
        end
      end
    end

    describe "ordering" do
      let!(:lead_provider_delivery_partnership1) { FactoryBot.create(:lead_provider_delivery_partnership) }
      let!(:lead_provider_delivery_partnership2) { travel_to(1.day.ago) { FactoryBot.create(:lead_provider_delivery_partnership) } }

      describe "default order" do
        it "returns delivery partners ordered by created_at, in ascending order" do
          query = described_class.new
          expect(query.delivery_partners).to eq([lead_provider_delivery_partnership2.delivery_partner, lead_provider_delivery_partnership1.delivery_partner])
        end
      end

      describe "order by created_at, in descending order" do
        it "returns delivery partners in correct order" do
          query = described_class.new(sort: "-created_at")
          expect(query.delivery_partners).to eq([lead_provider_delivery_partnership1.delivery_partner, lead_provider_delivery_partnership2.delivery_partner])
        end
      end

      describe "order by updated_at, in ascending order" do
        it "returns delivery partners in correct order" do
          query = described_class.new(sort: "+updated_at")
          expect(query.delivery_partners).to eq([lead_provider_delivery_partnership2.delivery_partner, lead_provider_delivery_partnership1.delivery_partner])
        end
      end

      describe "order by updated_at, in descending order" do
        it "returns delivery partners in correct order" do
          query = described_class.new(sort: "-updated_at")
          expect(query.delivery_partners).to eq([lead_provider_delivery_partnership1.delivery_partner, lead_provider_delivery_partnership2.delivery_partner])
        end
      end
    end
  end

  describe "#delivery_partner_by_api_id" do
    let(:lead_provider) { FactoryBot.create(:lead_provider) }

    it "returns the delivery partners for a given id" do
      delivery_partner = FactoryBot.create(:delivery_partner)
      query = described_class.new

      expect(query.delivery_partner_by_api_id(delivery_partner.api_id)).to eq(delivery_partner)
    end

    it "raises an error if the delivery partner does not exist" do
      query = described_class.new

      expect { query.delivery_partner_by_api_id("XXX123") }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises an error if the delivery partner is not in the filtered query" do
      lead_provider_delivery_partnership1 = FactoryBot.create(:lead_provider_delivery_partnership)
      lead_provider_delivery_partnership2 = FactoryBot.create(:lead_provider_delivery_partnership)

      query = described_class.new(lead_provider: lead_provider_delivery_partnership1.active_lead_provider.lead_provider)

      expect { query.delivery_partner_by_api_id(lead_provider_delivery_partnership2.delivery_partner.api_id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises an error if an api_id is not supplied" do
      expect { described_class.new.delivery_partner_by_api_id(nil) }.to raise_error(ArgumentError, "You must specify an api_id")
    end
  end

  describe "#delivery_partner_by_id" do
    it "returns the delivery_partner for a given id" do
      delivery_partner = FactoryBot.create(:delivery_partner)
      query = described_class.new

      expect(query.delivery_partner_by_id(delivery_partner.id)).to eq(delivery_partner)
    end

    it "raises an error if the delivery partner does not exist" do
      query = described_class.new

      expect { query.delivery_partner_by_id("XXX123") }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises an error if the delivery partner is not in the filtered query" do
      lead_provider_delivery_partnership1 = FactoryBot.create(:lead_provider_delivery_partnership)
      lead_provider_delivery_partnership2 = FactoryBot.create(:lead_provider_delivery_partnership)

      query = described_class.new(lead_provider: lead_provider_delivery_partnership1.active_lead_provider.lead_provider)

      expect { query.delivery_partner_by_id(lead_provider_delivery_partnership2.delivery_partner.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises an error if an id is not supplied" do
      expect { described_class.new.delivery_partner_by_id(nil) }.to raise_error(ArgumentError, "You must specify an id")
    end
  end
end
