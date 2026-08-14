RSpec.describe FrameworkAgreements::SeedFromPrevious do
  subject(:service) { described_class.new(framework_agreement: teach_first_activation_next) }

  # given a new contract_period...
  let!(:contract_period_next) { FactoryBot.create(:contract_period, :next, :with_schedules, mentor_funding_enabled: true) }
  # and an old contract_period...
  let!(:contract_period_current) { FactoryBot.create(:contract_period, :current, :with_schedules) }

  # given a lead provider, active in both periods...
  let(:teach_first) { FactoryBot.create(:lead_provider, name: "Teach First") }
  let(:teach_first_activation_next) { FactoryBot.create(:framework_agreement, lead_provider: teach_first, contract_period: contract_period_next) }
  let!(:teach_first_activation_current) { FactoryBot.create(:framework_agreement, lead_provider: teach_first, contract_period: contract_period_current) }

  describe "building subordinates from the previous activation's subordinate records" do
    before do
      create_subordinate_records(teach_first_activation_current)
      service.call
    end

    describe "delivery_partnerships" do
      let(:previous_partnerships) { teach_first_activation_current.lead_provider_delivery_partnerships }
      let(:new_partnerships) { teach_first_activation_next.lead_provider_delivery_partnerships }

      it "builds new delivery partnerships mirroring the previous ones" do
        expect(new_partnerships.size).to eq previous_partnerships.size
        expect(new_partnerships.map(&:delivery_partner))
          .to match_array(previous_partnerships.map(&:delivery_partner))
      end
    end

    describe "contracts" do
      let(:previous_contract) { teach_first_activation_current.contracts.first }
      let(:new_contract) { teach_first_activation_next.contracts.first }

      it "builds a single new contract based on the latest previous one" do
        expect(teach_first_activation_next.contracts.size).to eq 1
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
          fee_attributes = %i[recruitment_target setup_fee uplift_fee_per_declaration uplift_target_ratio monthly_service_fee]
          expect(new_contract.banded_fee_structure.slice(*fee_attributes))
            .to eq(previous_contract.banded_fee_structure.slice(*fee_attributes))
          expect(new_contract.banded_fee_structure).not_to eq(previous_contract.banded_fee_structure)
        end

        it "builds terms for the new banded_fee_structure, based on the previous" do
          band_term_attributes = %i[fee_per_declaration output_fee_ratio service_fee_ratio]
          expect(new_contract.banded_fee_structure.band_terms.map { |t| t.slice(*band_term_attributes) })
          .to match_array(previous_contract.banded_fee_structure.band_terms.map { |t| t.slice(*band_term_attributes) })
          expect(new_contract.banded_fee_structure.band_terms).not_to include(*previous_contract.banded_fee_structure.band_terms)
        end

        it "builds bands for the new banded_fee_structure, based on the previous" do
          band_attributes = %i[allocation_order capacity]
          expect(new_contract.banded_fee_structure.bands.map { |t| t.slice(*band_attributes) })
            .to match_array(previous_contract.banded_fee_structure.bands.map { |t| t.slice(*band_attributes) })
          expect(new_contract.banded_fee_structure.bands).not_to include(*previous_contract.banded_fee_structure.bands)
          expect(new_contract.banded_fee_structure.bands.first.framework_agreement.lead_provider).to eq(previous_contract.banded_fee_structure.bands.first.framework_agreement.lead_provider)
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
    let!(:earlier_contract) { FactoryBot.create(:contract, :for_ittecf_ectp, framework_agreement: teach_first_activation_current, vat_rate: 0.10) }
    let!(:latest_contract) { FactoryBot.create(:contract, :for_ittecf_ectp, framework_agreement: teach_first_activation_current, vat_rate: 0.20) }

    before do
      FactoryBot.create_list(:lead_provider_delivery_partnership, 3, framework_agreement: teach_first_activation_current)
      FactoryBot.create(:statement, :paid, framework_agreement: teach_first_activation_current, contract: earlier_contract, month: 11, year: contract_period_current.year)
      FactoryBot.create(:statement, :paid, framework_agreement: teach_first_activation_current, contract: latest_contract, month: 8, year: contract_period_current.year + 3)
      service.call
    end

    it "builds a single new contract based on the contract owning the latest statement, rolling every previous statement onto it" do
      new_contracts = teach_first_activation_next.contracts
      expect(new_contracts.size).to eq 1
      expect(new_contracts.first.vat_rate).to eq 0.20
      expect(new_contracts.first.statements.map { |s| [s.month, s.year] })
        .to contain_exactly([11, contract_period_next.year], [8, contract_period_next.year + 3])
    end
  end

  context "when no framework_agreement is given" do
    it "raises an ArgumentError" do
      expect { described_class.new(framework_agreement: nil) }
        .to raise_error(ArgumentError, /framework_agreement is required/)
    end
  end

  context "when there is no previous activation for the lead provider" do
    before { teach_first_activation_current.destroy! }

    it "raises an error" do
      expect { service.call }
        .to raise_error(described_class::PreviousFrameworkAgreementError, /No previous activation found in #{contract_period_current.year} for Teach First/)
    end
  end

  context "when the previous activation has no subordinate data" do
    it "raises an error" do
      expect { service.call }
        .to raise_error(described_class::PreviousFrameworkAgreementError, /Key info for Teach First is missing previous delivery partnerships, contracts or statements/)
    end
  end

  context "when the previous activation is only partially populated" do
    let(:missing_data_error_message) { /Key info for Teach First is missing previous delivery partnerships, contracts or statements/ }

    context "with delivery partnerships but no contracts or statements" do
      before { FactoryBot.create_list(:lead_provider_delivery_partnership, 3, framework_agreement: teach_first_activation_current) }

      it "raises an error" do
        expect { service.call }.to raise_error(described_class::PreviousFrameworkAgreementError, missing_data_error_message)
      end
    end

    context "with a contract but no partnerships or statements" do
      before { FactoryBot.create(:contract, :for_ittecf_ectp, framework_agreement: teach_first_activation_current) }

      it "raises an error" do
        expect { service.call }.to raise_error(described_class::PreviousFrameworkAgreementError, missing_data_error_message)
      end
    end

    context "with partnerships and a contract but no statements" do
      before do
        FactoryBot.create_list(:lead_provider_delivery_partnership, 3, framework_agreement: teach_first_activation_current)
        FactoryBot.create(:contract, :for_ittecf_ectp, framework_agreement: teach_first_activation_current)
      end

      it "raises an error" do
        expect { service.call }.to raise_error(described_class::PreviousFrameworkAgreementError, missing_data_error_message)
      end
    end

    context "with a contract and statements but no partnerships" do
      before do
        contract = FactoryBot.create(:contract, :for_ittecf_ectp, framework_agreement: teach_first_activation_current)
        FactoryBot.create(:statement, :paid, framework_agreement: teach_first_activation_current, contract:, month: 11, year: contract_period_current.year)
      end

      it "raises an error" do
        expect { service.call }.to raise_error(described_class::PreviousFrameworkAgreementError, missing_data_error_message)
      end
    end
  end

  context "when the framework agreement already has data" do
    before do
      create_subordinate_records(teach_first_activation_current)
      FactoryBot.create(:lead_provider_delivery_partnership, framework_agreement: teach_first_activation_next)
    end

    it "raises an error rather than duplicating data" do
      expect { service.call }
        .to raise_error(described_class::AlreadyPopulatedError, /Teach First already has data for #{contract_period_next.year}/)
    end
  end

private

  def create_subordinate_records(framework_agreement)
    FactoryBot.create_list(:lead_provider_delivery_partnership, 3, framework_agreement:)
    contract = FactoryBot.create(:contract, :for_ittecf_ectp, framework_agreement:)

    3.times do
      band = FactoryBot.create(:framework_agreement_band, framework_agreement:)
      FactoryBot.create(:contract_banded_fee_structure_band_term,
                        banded_fee_structure: contract.banded_fee_structure,
                        band:)
    end

    contract_year = framework_agreement.contract_period.year
    date = Date.new(contract_year, 11, 1)
    # Statements span November of contract_year through August three years later
    while date <= Date.new(contract_year + 3, 8, 1)
      FactoryBot.create(:statement, :paid, framework_agreement:, contract:, month: date.month, year: date.year)
      date = date.next_month
    end
  end
end
