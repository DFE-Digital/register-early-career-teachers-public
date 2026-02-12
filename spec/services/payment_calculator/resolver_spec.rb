describe PaymentCalculator::Resolver do
  describe "#calculators" do
    let(:statement) { FactoryBot.create(:statement, :open) }

    context "when contract type is ittecf_ectp" do
      subject(:calculator) { calculators.first }

      let(:calculators) { described_class.new(contract:, statement:).calculators }
      let(:contract) { FactoryBot.create(:contract, :for_ittecf_ectp) }

      it { expect(calculators.size).to eq(1) }
      it { is_expected.to be_a(PaymentCalculator::FlatRate) }
      it { expect(calculator).to have_attributes(statement:, flat_rate_fee_structure: contract.flat_rate_fee_structure) }

      describe "declaration_selector" do
        it "filters declarations to mentors only" do
          school_partnership = FactoryBot.create(:school_partnership, :for_year, year: statement.contract_period.year)

          ect_training_period = FactoryBot.create(:training_period, :for_ect, school_partnership:)
          FactoryBot.create(:declaration, training_period: ect_training_period)

          mentor_training_period = FactoryBot.create(:training_period, :for_mentor, school_partnership:)
          mentor_declaration = FactoryBot.create(:declaration, training_period: mentor_training_period)

          expect(calculator.declaration_selector.call(Declaration.all)).to contain_exactly(mentor_declaration)
        end
      end
    end

    context "when contract type is not supported" do
      let(:contract) { FactoryBot.create(:contract, :for_ittecf_ectp) }

      it "raises ContractTypeNotSupportedError" do
        allow(contract).to receive(:contract_type).and_return("unsupported")

        expect { described_class.new(contract:, statement:).calculators }
          .to raise_error(
            PaymentCalculator::Resolver::ContractTypeNotSupportedError,
            "No payment calculator exists for contract type: unsupported"
          )
      end
    end
  end
end
