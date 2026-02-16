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
    it { is_expected.to belong_to(:active_lead_provider) }
    it { is_expected.to belong_to(:banded_fee_structure).class_name("Contract::BandedFeeStructure").optional }
    it { is_expected.to belong_to(:flat_rate_fee_structure).class_name("Contract::FlatRateFeeStructure").optional }
    it { is_expected.to have_many(:statements).inverse_of(:contract) }
  end

  describe "validations" do
    subject { FactoryBot.create(:contract) }

    it { is_expected.to validate_presence_of(:contract_type).with_message("Enter a contract type") }
    it { is_expected.to validate_inclusion_of(:contract_type).in_array(Contract.contract_types.keys).with_message("Choose a valid contract type") }
    it { is_expected.to validate_presence_of(:vat_rate).with_message("VAT rate is required") }
    it { is_expected.to validate_numericality_of(:vat_rate).is_in(0..1).with_message("VAT rate must be between 0 and 1") }

    context "when active_lead_provider is nil" do
      subject(:contract) { FactoryBot.build(:contract, active_lead_provider: nil) }

      it "is not valid" do
        expect(contract).not_to be_valid
        expect(contract.errors[:active_lead_provider]).to include("An active lead provider must be set")
      end
    end

    context "when contract type is `ITTECF_ECTP`" do
      subject { FactoryBot.create(:contract, :for_ittecf_ectp) }

      it { is_expected.to validate_presence_of(:ecf_contract_version).with_message("ECF contract version must be provided for ITTECF_ECTP contracts") }
      it { is_expected.to validate_presence_of(:ecf_mentor_contract_version).with_message("ECF mentor contract version must be provided for ITTECF_ECTP contracts") }
      it { is_expected.to validate_presence_of(:flat_rate_fee_structure).with_message("Flat rate fee structure must be provided for ITTECF_ECTP contracts") }
      it { is_expected.to validate_presence_of(:banded_fee_structure).with_message("Banded fee structure must be provided for ITTECF_ECTP contracts") }
      it { is_expected.to validate_uniqueness_of(:flat_rate_fee_structure).with_message("Contract with the same flat rate fee structure already exists") }
      it { is_expected.to validate_uniqueness_of(:banded_fee_structure).with_message("Contract with the same banded fee structure already exists") }
    end

    context "when contract type is `ECF`" do
      subject { FactoryBot.create(:contract, :for_ecf) }

      it { is_expected.to validate_presence_of(:ecf_contract_version).with_message("ECF contract version must be provided for ECF contracts") }
      it { is_expected.to validate_presence_of(:banded_fee_structure).with_message("Banded fee structure must be provided for ECF contracts") }
      it { is_expected.to validate_absence_of(:flat_rate_fee_structure).with_message("Flat rate fee structure must be blank for ECF contracts") }
      it { is_expected.to validate_uniqueness_of(:banded_fee_structure).with_message("Contract with the same banded fee structure already exists") }

      it "allows multiple ECF contracts to have a NULL flat_rate_fee_structure" do
        FactoryBot.create(:contract, :for_ecf, flat_rate_fee_structure: nil)
        expect { FactoryBot.create(:contract, :for_ecf, flat_rate_fee_structure: nil) }.not_to raise_error
      end
    end
  end

  describe "immutable active_lead_provider_id" do
    let(:active_lead_provider) { FactoryBot.create(:active_lead_provider) }

    context "when creating a new contract" do
      let(:contract) { FactoryBot.build(:contract, active_lead_provider:) }

      it "assigns the active lead provider" do
        expect { contract.save! }.not_to raise_error
        expect(contract.active_lead_provider).to eq(active_lead_provider)
      end
    end

    context "when updating an existing contract" do
      let(:other_active_lead_provider) { FactoryBot.create(:active_lead_provider) }
      let(:contract) { FactoryBot.create(:contract, active_lead_provider:) }

      it "raises an error" do
        expect { contract.update!(active_lead_provider: other_active_lead_provider) }
          .to raise_error(ActiveRecord::ReadonlyAttributeError)
        expect(contract.active_lead_provider).to eq(active_lead_provider)
      end
    end
  end
end
