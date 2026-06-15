RSpec.describe ActiveLeadProviders::SeedFromPrevious do
  subject(:service) { described_class.new(active_lead_provider: teach_first_activation_2026) }

  # given a new contract_period...
  let!(:contract_period_2026) { FactoryBot.create(:contract_period, :with_schedules, year: 2026, mentor_funding_enabled: true) }
  # and an old contract_period...
  let!(:contract_period_2025) { FactoryBot.create(:contract_period, :with_schedules, year: 2025) }

  # given a lead provider, active in both periods...
  let(:teach_first) { FactoryBot.create(:lead_provider, name: "Teach First") }
  let(:teach_first_activation_2026) { FactoryBot.create(:active_lead_provider, lead_provider: teach_first, contract_period: contract_period_2026) }
  let!(:teach_first_activation_2025) { FactoryBot.create(:active_lead_provider, lead_provider: teach_first, contract_period: contract_period_2025) }

  describe "building subordinates from the previous activation's subordinate records" do
    before do
      create_subordinate_records(teach_first_activation_2025)
      service.call
    end

    describe "delivery_partnerships" do
      let(:previous_partnerships) { teach_first_activation_2025.lead_provider_delivery_partnerships }
      let(:new_partnerships) { teach_first_activation_2026.lead_provider_delivery_partnerships }

      it "builds new delivery partnerships mirroring the previous ones" do
        expect(new_partnerships.size).to eq previous_partnerships.size
        expect(new_partnerships.map(&:delivery_partner))
          .to match_array(previous_partnerships.map(&:delivery_partner))
      end
    end

    describe "contracts" do
      let(:previous_contract) { teach_first_activation_2025.contracts.first }
      let(:new_contract) { teach_first_activation_2026.contracts.first }

      it "builds a single new contract based on the latest previous one" do
        expect(teach_first_activation_2026.contracts.size).to eq 1
        expect(new_contract.lead_provider).to eq teach_first
        expect(new_contract.contract_type).to eq "ittecf_ectp"
      end

      describe "statements" do
        let(:previous_statements) { previous_contract.statements }
        let(:new_statements) { new_contract.statements }

        it "builds open statements for the new contract period, mirroring the previous ones" do
          expect(new_statements.size).to eq previous_statements.size
          expect(new_statements.map(&:status).uniq).to eq %w[open]
          expect(new_statements.map { |s| [s.month, s.year] })
            .to match_array(previous_statements.map { |s| [s.month, s.year + 1] })
        end
      end

      describe "contract fee structures" do
        it "builds a new banded_fee_structure for the new contract, based on the previous" do
          fee_attributes = %i[recruitment_target setup_fee uplift_fee_per_declaration monthly_service_fee]
          expect(new_contract.banded_fee_structure.slice(*fee_attributes))
            .to eq(previous_contract.banded_fee_structure.slice(*fee_attributes))
          expect(new_contract.banded_fee_structure).not_to eq(previous_contract.banded_fee_structure)
        end

        it "builds bands for the new banded_fee_structure" do
          band_attributes = %i[priority capacity fee_per_declaration output_fee_ratio service_fee_ratio]
          expect(new_contract.banded_fee_structure.bands.map { |b| b.slice(*band_attributes) })
            .to match_array(previous_contract.banded_fee_structure.bands.map { |b| b.slice(*band_attributes) })
          expect(new_contract.banded_fee_structure.bands).not_to include(*previous_contract.banded_fee_structure.bands)
        end

        it "builds a new flat_rate_fee_structure for the new contract, based on the previous" do
          flat_rate_attributes = %i[recruitment_target fee_per_declaration]
          expect(new_contract.flat_rate_fee_structure.slice(*flat_rate_attributes))
            .to eq(previous_contract.flat_rate_fee_structure.slice(*flat_rate_attributes))
          expect(new_contract.flat_rate_fee_structure).not_to eq(previous_contract.flat_rate_fee_structure)
        end
      end
    end
  end

  context "when the previous activation has multiple contracts" do
    let!(:earlier_contract) { FactoryBot.create(:contract, :for_ittecf_ectp, active_lead_provider: teach_first_activation_2025, vat_rate: 0.10) }
    let!(:latest_contract) { FactoryBot.create(:contract, :for_ittecf_ectp, active_lead_provider: teach_first_activation_2025, vat_rate: 0.20) }

    before do
      FactoryBot.create_list(:lead_provider_delivery_partnership, 3, active_lead_provider: teach_first_activation_2025)
      FactoryBot.create(:statement, :paid, active_lead_provider: teach_first_activation_2025, contract: earlier_contract, month: 11, year: 2025)
      FactoryBot.create(:statement, :paid, active_lead_provider: teach_first_activation_2025, contract: latest_contract, month: 8, year: 2028)
      service.call
    end

    it "builds a single new contract based on the contract owning the latest statement, rolling every previous statement onto it" do
      new_contracts = teach_first_activation_2026.contracts
      expect(new_contracts.size).to eq 1
      expect(new_contracts.first.vat_rate).to eq 0.20
      expect(new_contracts.first.statements.map { |s| [s.month, s.year] })
        .to contain_exactly([11, 2026], [8, 2029])
    end
  end

  context "when no active_lead_provider is given" do
    it "raises an ArgumentError" do
      expect { described_class.new(active_lead_provider: nil) }
        .to raise_error(ArgumentError, /active_lead_provider is required/)
    end
  end

  context "when there is no previous activation for the lead provider" do
    before { teach_first_activation_2025.destroy! }

    it "raises an error" do
      expect { service.call }
        .to raise_error(described_class::PreviousActiveLeadProviderError, /No previous activation found in 2025 for Teach First/)
    end
  end

  context "when the previous activation has no subordinate data" do
    it "raises an error" do
      expect { service.call }
        .to raise_error(described_class::PreviousActiveLeadProviderError, /Key info for Teach First is missing previous delivery partnerships, contracts or statements/)
    end
  end

  context "when the previous activation is only partially populated" do
    let(:missing_data_error_message) { /Key info for Teach First is missing previous delivery partnerships, contracts or statements/ }

    context "with delivery partnerships but no contracts or statements" do
      before { FactoryBot.create_list(:lead_provider_delivery_partnership, 3, active_lead_provider: teach_first_activation_2025) }

      it "raises an error" do
        expect { service.call }.to raise_error(described_class::PreviousActiveLeadProviderError, missing_data_error_message)
      end
    end

    context "with a contract but no partnerships or statements" do
      before { FactoryBot.create(:contract, :for_ittecf_ectp, active_lead_provider: teach_first_activation_2025) }

      it "raises an error" do
        expect { service.call }.to raise_error(described_class::PreviousActiveLeadProviderError, missing_data_error_message)
      end
    end

    context "with partnerships and a contract but no statements" do
      before do
        FactoryBot.create_list(:lead_provider_delivery_partnership, 3, active_lead_provider: teach_first_activation_2025)
        FactoryBot.create(:contract, :for_ittecf_ectp, active_lead_provider: teach_first_activation_2025)
      end

      it "raises an error" do
        expect { service.call }.to raise_error(described_class::PreviousActiveLeadProviderError, missing_data_error_message)
      end
    end

    context "with a contract and statements but no partnerships" do
      before do
        contract = FactoryBot.create(:contract, :for_ittecf_ectp, active_lead_provider: teach_first_activation_2025)
        FactoryBot.create(:statement, :paid, active_lead_provider: teach_first_activation_2025, contract:, month: 11, year: 2025)
      end

      it "raises an error" do
        expect { service.call }.to raise_error(described_class::PreviousActiveLeadProviderError, missing_data_error_message)
      end
    end
  end

  context "when the active lead provider already has data" do
    before do
      create_subordinate_records(teach_first_activation_2025)
      FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider: teach_first_activation_2026)
    end

    it "raises an error rather than duplicating data" do
      expect { service.call }
        .to raise_error(described_class::AlreadyPopulatedError, /Teach First already has data for 2026/)
    end
  end

private

  def create_subordinate_records(active_lead_provider)
    FactoryBot.create_list(:lead_provider_delivery_partnership, 3, active_lead_provider:)
    contract = FactoryBot.create(:contract, :for_ittecf_ectp, active_lead_provider:)
    contract_year = active_lead_provider.contract_period.year
    date = Date.new(contract_year, 11, 1)
    # Statements span November of contract_year through August three years later
    while date <= Date.new(contract_year + 3, 8, 1)
      FactoryBot.create(:statement, :paid, active_lead_provider:, contract:, month: date.month, year: date.year)
      date = date.next_month
    end
  end
end
