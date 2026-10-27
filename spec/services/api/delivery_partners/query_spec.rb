RSpec.describe API::DeliveryPartners::Query do
  let!(:framework_agreement3) { FactoryBot.create(:framework_agreement, lead_provider:, contract_period: contract_period3) }
  let!(:framework_agreement2) { FactoryBot.create(:framework_agreement, lead_provider:, contract_period: contract_period2) }
  let!(:framework_agreement1) { FactoryBot.create(:framework_agreement, lead_provider:, contract_period: contract_period1) }
  let(:contract_period3) { FactoryBot.create(:contract_period) }
  let(:contract_period2) { FactoryBot.create(:contract_period) }
  let(:contract_period1) { FactoryBot.create(:contract_period) }
  let!(:lead_provider_id) { lead_provider.id }
  let(:lead_provider) { FactoryBot.create(:lead_provider) }

  describe "including associations" do
    shared_examples "included associations" do
      it { expect(result.association(association)).to be_loaded }

      context "when no associations are included" do
        let(:association) { nil }

        it { expect(result).not_to have_any_loaded_associations }
      end
    end

    let(:association) { :framework_agreements }
    let(:instance) { described_class.new(lead_provider_id:, included_associations: [association]) }
    let(:delivery_partner) { FactoryBot.create(:delivery_partner) }
    let(:lead_provider) { FactoryBot.create(:lead_provider) }
    let(:lead_provider_id) { lead_provider.id }
    let!(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, lead_provider:, delivery_partner:) }

    describe "#delivery_partners" do
      subject(:result) { instance.delivery_partners.first }

      include_examples "included associations"
    end

    describe "#delivery_partner_by_api_id" do
      subject(:result) { instance.delivery_partner_by_api_id(delivery_partner.api_id) }

      include_examples "included associations"
    end

    describe "#delivery_partner_by_id" do
      subject(:result) { instance.delivery_partner_by_id(delivery_partner.id) }

      include_examples "included associations"
    end
  end

  describe "#delivery_partners" do
    let!(:delivery_partner1) { FactoryBot.create(:lead_provider_delivery_partnership, framework_agreement: framework_agreement1).delivery_partner }
    let!(:delivery_partner2) { FactoryBot.create(:lead_provider_delivery_partnership, framework_agreement: framework_agreement2).delivery_partner }
    let!(:delivery_partner3) { FactoryBot.create(:lead_provider_delivery_partnership, framework_agreement: framework_agreement3).delivery_partner }

    describe "scoped by `lead_provider`" do
      let!(:delivery_partner2) { FactoryBot.create(:lead_provider_delivery_partnership).delivery_partner }
      let!(:delivery_partner3) { FactoryBot.create(:lead_provider_delivery_partnership).delivery_partner }

      it "scopes by `lead_provider`" do
        query = described_class.new(lead_provider_id:)

        expect(query.delivery_partners).to contain_exactly(delivery_partner1)
      end

      it "returns empty if no delivery partners are found for the given `lead_provider`" do
        query = described_class.new(lead_provider_id: FactoryBot.create(:lead_provider).id)

        expect(query.delivery_partners).to be_empty
      end
    end

    describe "filtering", :with_metadata do
      describe "by `contract_period_years`" do
        context "when `contract_period_years` param is omitted" do
          it "returns all delivery partners linked to the lead provider" do
            expect(described_class.new(lead_provider_id:).delivery_partners).to contain_exactly(delivery_partner1, delivery_partner2, delivery_partner3)
          end
        end

        it "filters by `contract_period_years`" do
          query = described_class.new(lead_provider_id:, contract_period_years: contract_period2.year.to_s)

          expect(query.delivery_partners).to eq([delivery_partner2])
        end

        it "filters by multiple `contract_period_years`" do
          query1 = described_class.new(lead_provider_id:, contract_period_years: [contract_period1.year, contract_period2.year])
          expect(query1.delivery_partners).to contain_exactly(delivery_partner1, delivery_partner2)

          query2 = described_class.new(lead_provider_id:, contract_period_years: [contract_period2.year.to_s, contract_period3.year.to_s])
          expect(query2.delivery_partners).to contain_exactly(delivery_partner2, delivery_partner3)
        end

        it "returns no delivery partners if no `contract_period_years` are found" do
          query = described_class.new(lead_provider_id:, contract_period_years: "0000")

          expect(query.delivery_partners).to be_empty
        end

        it "returns no delivery partners if `contract_period_years` is an empty array" do
          query = described_class.new(lead_provider_id:, contract_period_years: [])

          expect(query.delivery_partners).to be_empty
        end

        it "returns all delivery partners if `contract_period_years` is an empty string" do
          query = described_class.new(lead_provider_id:, contract_period_years: "")

          expect(query.delivery_partners).to contain_exactly(delivery_partner1, delivery_partner2, delivery_partner3)
        end

        it "ignores invalid `contract_period_years`" do
          query = described_class.new(lead_provider_id:, contract_period_years: [contract_period1.year, 1099])

          expect(query.delivery_partners).to contain_exactly(delivery_partner1)
        end

        it "does not filter by `contract_period_years` if blank" do
          query = described_class.new(lead_provider_id:, contract_period_years: " ")

          expect(query.delivery_partners).to contain_exactly(delivery_partner1, delivery_partner2, delivery_partner3)
        end
      end
    end

    describe "ordering" do
      before do
        delivery_partner1.update!(created_at: 1.week.ago, updated_at: 1.day.ago)
        delivery_partner2.update!(created_at: 2.days.ago, updated_at: 2.days.ago)
      end

      describe "default order" do
        it "returns delivery partners ordered by created_at, in ascending order" do
          query = described_class.new(lead_provider_id:)

          expect(query.delivery_partners).to eq([delivery_partner1, delivery_partner2, delivery_partner3])
        end
      end

      describe "order by created_at, in descending order" do
        it "returns delivery partners in correct order" do
          query = described_class.new(lead_provider_id:, sort: { created_at: :desc })

          expect(query.delivery_partners).to eq([delivery_partner3, delivery_partner2, delivery_partner1])
        end
      end

      describe "order by updated_at, in ascending order" do
        it "returns delivery partners in correct order" do
          query = described_class.new(lead_provider_id:, sort: { updated_at: :asc })

          expect(query.delivery_partners).to eq([delivery_partner2, delivery_partner1, delivery_partner3])
        end
      end

      describe "order by updated_at, in descending order" do
        it "returns delivery partners in correct order" do
          query = described_class.new(lead_provider_id:, sort: { updated_at: :desc })
          expect(query.delivery_partners).to eq([delivery_partner3, delivery_partner1, delivery_partner2])
        end
      end
    end
  end

  describe "#delivery_partner_by_api_id" do
    let!(:delivery_partner) { FactoryBot.create(:lead_provider_delivery_partnership, framework_agreement: framework_agreement1).delivery_partner }

    it "returns the delivery partners for a given id" do
      query = described_class.new(lead_provider_id:)

      expect(query.delivery_partner_by_api_id(delivery_partner.api_id)).to eq(delivery_partner)
    end

    it "raises an error if the delivery partner does not exist" do
      query = described_class.new(lead_provider_id:)

      expect { query.delivery_partner_by_api_id("XXX123") }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises an error if the delivery partner is not in the filtered query" do
      different_provider_delivery_partner = FactoryBot.create(:lead_provider_delivery_partnership).delivery_partner

      query = described_class.new(lead_provider_id:)

      expect { query.delivery_partner_by_api_id(different_provider_delivery_partner.api_id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises an error if an api_id is not supplied" do
      expect { described_class.new(lead_provider_id:).delivery_partner_by_api_id(nil) }.to raise_error(ArgumentError, "api_id needed")
    end
  end

  describe "#delivery_partner_by_id" do
    let!(:delivery_partner) { FactoryBot.create(:lead_provider_delivery_partnership, framework_agreement: framework_agreement1).delivery_partner }

    it "returns the delivery_partner for a given id" do
      query = described_class.new(lead_provider_id:)

      expect(query.delivery_partner_by_id(delivery_partner.id)).to eq(delivery_partner)
    end

    it "raises an error if the delivery partner does not exist" do
      query = described_class.new(lead_provider_id:)

      expect { query.delivery_partner_by_id("XXX123") }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises an error if the delivery partner is not in the filtered query" do
      different_provider_delivery_partner = FactoryBot.create(:lead_provider_delivery_partnership).delivery_partner

      query = described_class.new(lead_provider_id:)

      expect { query.delivery_partner_by_id(different_provider_delivery_partner.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises an error if an id is not supplied" do
      expect { described_class.new(lead_provider_id:).delivery_partner_by_id(nil) }.to raise_error(ArgumentError, "id needed")
    end
  end
end
