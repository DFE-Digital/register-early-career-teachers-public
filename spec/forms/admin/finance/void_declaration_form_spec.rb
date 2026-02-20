RSpec.describe Admin::Finance::VoidDeclarationForm, type: :model do
  subject(:form) { described_class.new(declaration:, author:, confirmed:) }

  let(:confirmed) { "1" }
  let(:declaration) { FactoryBot.create(:declaration, :no_payment) }
  let(:author) { FactoryBot.create(:dfe_user, role: "finance") }

  shared_examples "does not call the void service" do
    it "does not call the void service" do
      expect(Declarations::Void).not_to receive(:new)
      subject
    end
  end

  shared_examples "does not call the clawback service" do
    it "does not call the clawback service" do
      expect(Declarations::Clawback).not_to receive(:new)
      subject
    end
  end

  describe "#void!" do
    subject { form.void! }

    context "when the form is not confirmed" do
      let(:confirmed) { "0" }

      it { is_expected.to be false }
      it { expect(form).to have_error(:confirmed) }

      include_examples "does not call the void service"
      include_examples "does not call the clawback service"
    end

    context "when the declaration is not voidable" do
      let(:declaration) { FactoryBot.create(:declaration, :voided) }

      it { is_expected.to be false }
      it { expect(form).to have_error(:declaration) }

      include_examples "does not call the void service"
      include_examples "does not call the clawback service"
    end

    context "when voiding an unpaid declaration" do
      it { is_expected.to be_truthy }

      it "calls the void service" do
        expect(Declarations::Void).to receive(:new).with(author:, declaration:, voided_by_user_id: author.id).and_call_original
        form.void!
      end

      include_examples "does not call the clawback service"
    end

    context "when voiding a paid declaration" do
      let(:declaration) { FactoryBot.create(:declaration, :paid) }

      it { is_expected.to be_truthy }

      include_examples "does not call the void service"

      it "calls the clawback service" do
        expect(Declarations::Clawback).to receive(:new).with(author:, declaration:, voided_by_user_id: author.id).and_call_original
        form.void!
      end
    end
  end
end
