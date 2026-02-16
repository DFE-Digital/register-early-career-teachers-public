describe PaymentCalculator::Resolver do
  describe "#calculators" do
    let(:statement) { FactoryBot.create(:statement, :open) }

    context "when contract type is ittecf_ectp" do
      subject(:calculator) { calculators.first }

      let(:calculators) { described_class.new(contract:, statement:).calculators }
      let(:contract) { FactoryBot.create(:contract, :for_ittecf_ectp) }

      it { expect(calculators.size).to eq(1) }
      it { is_expected.to be_a(PaymentCalculator::FlatRate) }

      it {
        expect(calculator).to have_attributes(statement:,
                                              flat_rate_fee_structure: contract.flat_rate_fee_structure,
                                              fee_proportions: { started: 0.5, completed: 0.5 })
      }

      describe "declaration_selector" do
        let(:contract_period) { FactoryBot.create(:contract_period, mentor_funding_enabled: false) }
        let(:statement) { FactoryBot.create(:statement, :open, contract_period:) }

        it "filters started/completed declarations to mentors only" do
          active_lead_provider = FactoryBot.create(:active_lead_provider, contract_period:)
          lead_provider_delivery_partnership = FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:)
          school_partnership = FactoryBot.create(:school_partnership, lead_provider_delivery_partnership:)

          ect_training_period = FactoryBot.create(:training_period, :for_ect, school_partnership:)
          FactoryBot.create(:declaration, training_period: ect_training_period)

          mentor_training_period = FactoryBot.create(:training_period, :for_mentor, school_partnership:)
          mentor_started_declaration = FactoryBot.create(:declaration, declaration_type: :started, training_period: mentor_training_period)
          mentor_completed_declaration = FactoryBot.create(:declaration, declaration_type: :completed, training_period: mentor_training_period)

          # create declarations for other declaration types to ensure they are not included by the selector
          Declaration.declaration_types.keys.reject { |type| %w[started completed].include?(type) }.each do |declaration_type|
            FactoryBot.create(:declaration, declaration_type:, training_period: mentor_training_period)
          end

          expect(calculator.declaration_selector.call(Declaration.all)).to contain_exactly(mentor_started_declaration, mentor_completed_declaration)
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
