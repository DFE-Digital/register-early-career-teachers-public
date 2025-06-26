RSpec.describe Admin::Statements::PaymentAuthorisationComponent, type: :component do
  subject { render_inline(component) }

  let(:statement) { FactoryBot.create(:statement, :payable, output_fee: true, marked_as_paid_at:) }
  let(:marked_as_paid_at) { nil }
  let(:component) { described_class.new statement: }

  context "service_fee statement" do
    let(:statement) { FactoryBot.create(:statement, :payable, output_fee: false) }

    it "does not render" do
      expect(subject.text).to be_blank
    end
  end

  context "output_fee statement" do
    context "can authorise payment" do
      before { allow(statement).to receive(:can_authorise_payment?).and_return(true) }

      it "renders correctly" do
        expect(subject).to have_button("Authorise for payment")
      end
    end

    context "marked as paid" do
      let(:marked_as_paid_at) { Time.zone.now }

      before { allow(statement).to receive(:can_authorise_payment?).and_return(false) }

      it "renders correctly" do
        expect(subject).not_to have_button("Authorise for payment")
        marked_as_paid_at = statement.marked_as_paid_at.in_time_zone("London").strftime("%-I:%M%P on %-e %B %Y")
        expect(subject).to have_content("Authorised for payment at #{marked_as_paid_at}")
      end
    end
  end
end
