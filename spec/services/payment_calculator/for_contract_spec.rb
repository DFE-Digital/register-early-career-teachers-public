describe PaymentCalculator::ForContract do
  describe "#calculators" do
    let(:statement) { FactoryBot.create(:statement, :open) }

    context "when contract type is ittecf_ectp" do
      subject { described_class.new(contract:, statement:) }

      let(:contract) { FactoryBot.create(:contract, :for_ittecf_ectp) }

      it "returns an array with one FlatRate" do
        calculators = subject.calculators

        expect(calculators.size).to eq(1)
        expect(calculators.first).to be_a(PaymentCalculator::FlatRate)
      end

      it "assigns the statement to the calculator" do
        calculator = subject.calculators.first

        expect(calculator.statement).to eq(statement)
      end

      it "assigns the flat_rate_fee_structure to the calculator" do
        calculator = subject.calculators.first

        expect(calculator.flat_rate_fee_structure).to eq(contract.flat_rate_fee_structure)
      end

      describe "declaration_selector" do
        it "filters declarations to mentors only" do
          calculator = subject.calculators.first
          mentor_declarations = double("mentor_declarations")
          test_declarations = double("declarations", mentors: mentor_declarations)

          expect(calculator.declaration_selector.call(test_declarations)).to eq(mentor_declarations)
        end
      end
    end

    context "when contract type is not supported" do
      let(:contract) { FactoryBot.create(:contract, :for_ittecf_ectp) }

      it "raises ContractTypeNotSupportedError" do
        allow(contract).to receive(:contract_type).and_return("unsupported")

        expect { described_class.new(contract:, statement:).calculators }
          .to raise_error(
            PaymentCalculator::ForContract::ContractTypeNotSupportedError,
            "No payment calculator exists for contract type: unsupported"
          )
      end
    end
  end
end
