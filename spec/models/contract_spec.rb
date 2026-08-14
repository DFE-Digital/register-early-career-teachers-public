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
    it { is_expected.to belong_to(:framework_agreement) }
    it { is_expected.to have_one(:lead_provider).through(:framework_agreement) }
    it { is_expected.to have_one(:banded_fee_structure).class_name("Contract::BandedFeeStructure").inverse_of(:contract) }
    it { is_expected.to have_one(:flat_rate_fee_structure).class_name("Contract::FlatRateFeeStructure").inverse_of(:contract) }
    it { is_expected.to have_one(:contract_period).through(:framework_agreement) }
    it { is_expected.to have_many(:statements).inverse_of(:contract) }
  end

  describe "scopes" do
    describe ".most_recent_first" do
      let(:framework_agreement) { FactoryBot.create(:framework_agreement) }
      let(:other_framework_agreement) { FactoryBot.create(:framework_agreement) }
      let!(:contract_1) { FactoryBot.create(:contract, framework_agreement:, created_at: 4.days.ago) }
      let!(:contract_2) { FactoryBot.create(:contract, framework_agreement:, created_at: 3.days.ago) }
      let!(:contract_3) { FactoryBot.create(:contract, framework_agreement:, created_at: 2.days.ago) }
      let!(:contract_4) { FactoryBot.create(:contract, framework_agreement: other_framework_agreement, created_at: 1.day.ago) }

      let(:result) { described_class.most_recent_first }

      it "orders contract by created_at in descending order" do
        expect(result.to_a).to eq([contract_4, contract_3, contract_2, contract_1])
      end

      it "returns contract with most recently created first" do
        expect(result.first).to eq(contract_4)
        expect(result.last).to eq(contract_1)
      end
    end
  end

  describe "validations" do
    subject { FactoryBot.create(:contract) }

    it { is_expected.to validate_presence_of(:contract_type).with_message("Enter a contract type") }
    it { is_expected.to validate_inclusion_of(:contract_type).in_array(Contract.contract_types.keys).with_message("Choose a valid contract type") }
    it { is_expected.to validate_presence_of(:vat_rate).with_message("VAT rate is required") }
    it { is_expected.to validate_numericality_of(:vat_rate).is_in(0..1).with_message("VAT rate must be between 0 and 1") }

    context "when framework_agreement is nil" do
      subject(:contract) { FactoryBot.build(:contract, framework_agreement: nil) }

      it "is not valid" do
        expect(contract).not_to be_valid
        expect(contract.errors[:framework_agreement]).to include("A lead provider framework agreement must be set")
      end
    end

    context "when contract type is `ITTECF_ECTP`" do
      subject { FactoryBot.build(:contract, :for_ittecf_ectp) }

      it { is_expected.to validate_presence_of(:flat_rate_fee_structure).with_message("Flat rate fee structure must be provided for ITTECF_ECTP contracts") }
      it { is_expected.to validate_presence_of(:banded_fee_structure).with_message("Banded fee structure must be provided for ITTECF_ECTP contracts") }
    end

    context "when contract type is `ECF`" do
      subject { FactoryBot.build(:contract, :for_ecf) }

      it { is_expected.to validate_presence_of(:banded_fee_structure).with_message("Banded fee structure must be provided for ECF contracts") }
      it { is_expected.to validate_absence_of(:flat_rate_fee_structure).with_message("Flat rate fee structure must be blank for ECF contracts") }

      it "allows multiple ECF contracts to have a NULL flat_rate_fee_structure" do
        FactoryBot.create(:contract, :for_ecf, flat_rate_fee_structure: nil)
        expect { FactoryBot.create(:contract, :for_ecf, flat_rate_fee_structure: nil) }.not_to raise_error
      end
    end
  end

  describe "delegations" do
    it { is_expected.to delegate_method(:editable?).to(:framework_agreement) }
  end

  describe "immutable active_lead_provider_id" do
    let(:framework_agreement) { FactoryBot.create(:framework_agreement) }

    context "when creating a new contract" do
      let(:contract) { FactoryBot.build(:contract, framework_agreement:) }

      it "assigns the framework agreement" do
        expect { contract.save! }.not_to raise_error
        expect(contract.framework_agreement).to eq(framework_agreement)
      end
    end

    context "when updating an existing contract" do
      let(:other_framework_agreement) { FactoryBot.create(:framework_agreement) }
      let(:contract) { FactoryBot.create(:contract, framework_agreement:) }

      it "raises an error" do
        expect { contract.update!(framework_agreement: other_framework_agreement) }
          .to raise_error(ActiveRecord::ReadonlyAttributeError)
        expect(contract.framework_agreement).to eq(framework_agreement)
      end
    end
  end

  describe "#applicable_vat_rate" do
    subject(:applicable_vat_rate) { contract.applicable_vat_rate }

    let(:lead_provider) { FactoryBot.create(:lead_provider, vat_registered:) }
    let(:framework_agreement) { FactoryBot.create(:framework_agreement, lead_provider:) }
    let(:contract) { FactoryBot.create(:contract, framework_agreement:, vat_rate: 0.2) }

    context "when the lead provider is VAT registered" do
      let(:vat_registered) { true }

      it { is_expected.to eq(0.2) }
    end

    context "when the lead provider is not VAT registered" do
      let(:vat_registered) { false }

      it { is_expected.to eq(0) }
    end
  end

  describe "#statement_range_description" do
    subject(:statement_range_description) { contract.statement_range_description }

    let(:contract) { FactoryBot.create(:contract) }

    context "with no statements" do
      it { is_expected.to eq("No statements") }
    end

    context "with a single statement" do
      before { FactoryBot.create(:statement, contract:, month: 1, year: 2025) }

      it { is_expected.to eq("January 2025") }
    end

    context "with multiple statements spanning different periods" do
      before do
        FactoryBot.create(:statement, contract:, month: 1, year: 2025)
        FactoryBot.create(:statement, contract:, month: 5, year: 2026)
      end

      it { is_expected.to eq("January 2025 - May 2026") }
    end
  end

  describe "#description" do
    subject(:description) { contract.description }

    context "when the contract type is `ITTECF_ECTP` with no statements" do
      let(:contract) { FactoryBot.create(:contract, :for_ittecf_ectp) }

      it { is_expected.to eq("ITTECF ECTP No statements") }
    end

    context "when the contract type is `ECF` with statements" do
      let(:contract) { FactoryBot.create(:contract, :for_ecf) }

      before do
        FactoryBot.create(:statement, contract:, month: 1, year: 2025)
        FactoryBot.create(:statement, contract:, month: 5, year: 2026)
      end

      it { is_expected.to eq("ECF January 2025 - May 2026") }
    end
  end
end
