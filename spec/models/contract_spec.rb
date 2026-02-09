describe Contract do
  describe "enums" do
    it "uses the contract type enum" do
      expect(subject).to define_enum_for(:contract_type)
                           .with_values({ ecf: "ecf",
                                          ittecf_ectp: "ittecf_ectp" })
                           .validating
                           .with_suffix(:contract_type)
                           .backed_by_column_of_type(:enum)
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:contract_banded_fee_structure).class_name("Contract::BandedFeeStructure").optional }
    it { is_expected.to belong_to(:contract_flat_rate_fee_structure).class_name("Contract::FlatRateFeeStructure").optional }
    it { is_expected.to have_many(:statements).inverse_of(:contract) }
  end

  describe "validations" do
    subject { FactoryBot.create(:contract) }

    it { is_expected.to validate_presence_of(:contract_type).with_message("Enter a contract type") }
    it { is_expected.to validate_uniqueness_of(:contract_type).scoped_to(:contract_flat_rate_fee_structure_id).with_message("Contract with the same type and fee structure already exists") }
    it { is_expected.to validate_inclusion_of(:contract_type).in_array(Contract.contract_types.keys).with_message("Choose a valid contract type") }

    context "when contract type is `ITTECF_ECTP`" do
      subject { FactoryBot.create(:contract, :for_mentor) }

      it { is_expected.to validate_presence_of(:contract_flat_rate_fee_structure).with_message("Flat rate fee structure must be provided for ITTECF_ECTP contracts") }
      it { is_expected.to validate_absence_of(:contract_banded_fee_structure).with_message("Banded fee structure must be blank for ITTECF_ECTP contracts") }
    end

    context "when contract type is `ECF`" do
      subject { FactoryBot.create(:contract, :for_ecf) }

      it { is_expected.to validate_presence_of(:contract_banded_fee_structure).with_message("Banded fee structure must be provided for ECF contracts") }
      it { is_expected.to validate_absence_of(:contract_flat_rate_fee_structure).with_message("Flat rate fee structure must be blank for ECF contracts") }
    end

    describe "contract statements have same lead provider and contract period" do
      let!(:contract) { FactoryBot.create(:contract) }
      let(:active_lead_provider) { FactoryBot.create(:active_lead_provider) }

      it "is valid when there are no statements associated with the contract" do
        expect(contract).to be_valid
      end

      it "is valid when all other statements associated with the same contract have the same lead provider and contract period" do
        FactoryBot.create(:statement, contract:, active_lead_provider:)
        FactoryBot.create(:statement, contract:, active_lead_provider:)

        contract.reload

        expect(contract).to be_valid
      end

      it "is invalid when there are other statements associated with the same contract that have different lead providers or contract periods" do
        FactoryBot.create(:statement, contract:, active_lead_provider:)

        another_contract_statement = FactoryBot.create(:statement, active_lead_provider: FactoryBot.create(:active_lead_provider))
        another_contract_statement.update_columns(contract_id: contract.id)

        contract.reload

        expect(contract).not_to be_valid
        expect(contract.errors[:base]).to include("This contract is associated with other statements linked to different lead providers/contract periods.")
      end
    end
  end
end
