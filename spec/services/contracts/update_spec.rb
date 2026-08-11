RSpec.describe Contracts::Update do
  subject(:service) { described_class.new(author:, contract:, params:) }

  let(:user) { FactoryBot.create(:user, :admin) }
  let(:author) { Sessions::Users::DfEPersona.new(email: user.email) }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider) }

  let(:contract) do
    FactoryBot.create(:contract, :for_ittecf_ectp,
                      active_lead_provider:)
  end
  let(:banded_fee_structure) { contract.banded_fee_structure }
  let!(:band_term) do
    FactoryBot.create(:contract_banded_fee_structure_band_term,
                      banded_fee_structure:,
                      band: alp_band,
                      fee_per_declaration: 100,
                      output_fee_ratio: 0.70,
                      service_fee_ratio: 0.30)
  end
  let(:alp_band) do
    FactoryBot.create(:active_lead_provider_band,
                      active_lead_provider:)
  end

  let(:output_fee_percentage) { 80 }

  let(:params) do
    {
      vat_rate: 0.1,
      banded_fee_structure_attributes: {
        id: banded_fee_structure.id,
        recruitment_target: 9_999,
        band_terms_attributes: [
          {
            id: band_term.id,
            band_id: band_term.band_id,
            fee_per_declaration: 9_999,
            output_fee_percentage:,
          },
        ],
      },
    }
  end

  before { allow(Events::Record).to receive(:record_contract_updated_event!) }

  it "updates the contract, fee structure, and band term, then records the event" do
    original_recruitment_target = banded_fee_structure.recruitment_target
    original_fee_per_declaration = band_term.fee_per_declaration
    original_output_fee_ratio = band_term.output_fee_ratio
    original_service_fee_ratio = band_term.service_fee_ratio
    original_vat_rate = contract.vat_rate

    result = service.call

    expect(result).to eq(contract)
    expect(result.vat_rate).to eq(0.1)
    expect(result.banded_fee_structure.recruitment_target).to eq(9_999)
    expect(band_term.reload.fee_per_declaration).to eq(9_999)
    expect(band_term.output_fee_ratio).to eq(0.80)
    expect(band_term.service_fee_ratio).to eq(0.20)

    expect(Events::Record).to have_received(:record_contract_updated_event!).with(
      hash_including(
        author:,
        contract:,
        modifications: hash_including(
          "vat_rate" => [original_vat_rate, 0.1],
          "banded_recruitment_target" => [original_recruitment_target, 9_999],
          "band_A_fee_per_declaration" => [original_fee_per_declaration, 9_999],
          "band_A_output_fee_ratio" => [original_output_fee_ratio, 0.80],
          "band_A_service_fee_ratio" => [original_service_fee_ratio, 0.20]
        )
      )
    )
  end

  context "when the band term is not changed" do
    let(:params) do
      {
        vat_rate: 0.1,
        banded_fee_structure_attributes: {
          id: banded_fee_structure.id,
          recruitment_target: 9_999,
          band_terms_attributes: [
            {
              id: band_term.id,
              band_id: band_term.band_id,
              fee_per_declaration: 100,
              output_fee_percentage: 70,
            },
          ],
        },
      }
    end

    it "only records modifications for changed attributes" do
      original_recruitment_target = banded_fee_structure.recruitment_target
      original_vat_rate = contract.vat_rate

      service.call

      expect(Events::Record).to have_received(:record_contract_updated_event!).with(
        hash_including(
          author:,
          contract:,
          modifications: hash_including(
            "vat_rate" => [original_vat_rate, 0.1],
            "banded_recruitment_target" => [original_recruitment_target, 9_999]
          )
        )
      )
      expect(Events::Record).to have_received(:record_contract_updated_event!).with(
        hash_including(
          modifications: hash_not_including(
            "band_A_fee_per_declaration",
            "band_A_output_fee_ratio",
            "band_A_service_fee_ratio"
          )
        )
      )
    end
  end

  context "when the output fee percentage is outside 0 to 100" do
    let(:output_fee_percentage) { 150 }

    it "does not update the contract or create an event" do
      expect { service.call }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Banded fee structure band terms output fee percentage Output fee percentage must be between 0 and 100")
      expect(Events::Record).not_to have_received(:record_contract_updated_event!)
    end
  end
end
