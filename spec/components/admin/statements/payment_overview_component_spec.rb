RSpec.describe Admin::Statements::PaymentOverviewComponent, type: :component do
  subject { described_class }

  let(:statement) { FactoryBot.create(:statement, contract:) }

  describe ".for" do
    context "when the statement is not present" do
      let(:statement) { nil }

      it "raises an error" do
        expect { subject.for(statement:) }.to raise_error(ArgumentError, "Statement not present")
      end
    end

    context "when the statement is for an ITTECF contract" do
      let(:contract) { FactoryBot.create(:contract, :for_ittecf_ectp) }

      it "returns the ECF component for ecf contracts" do
        expect(subject.for(statement:)).to be_a(Admin::Statements::PaymentOverview::IttecfEctpComponent)
      end
    end

    context "when the statement is for an ECF contract" do
      let(:contract) { FactoryBot.create(:contract, :for_ecf) }

      it "returns the ITTECF component for ittecf contracts" do
        expect(subject.for(statement:)).to be_a(Admin::Statements::PaymentOverview::ECFComponent)
      end
    end
  end
end
