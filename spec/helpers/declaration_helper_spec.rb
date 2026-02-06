RSpec.describe DeclarationHelper, type: :helper do
  let(:declaration) { FactoryBot.build(:declaration) }

  describe "#declaration_state_tag" do
    subject { helper.declaration_state_tag(declaration) }

    before do
      allow(declaration).to receive(:overall_status).and_return(overall_status)
    end

    context "when the overall status is 'no_payment'" do
      let(:overall_status) { "no_payment" }

      it { is_expected.to include("Submitted") }
      it { is_expected.to include("govuk-tag--light-blue") }
    end

    context "when the overall status is 'eligible'" do
      let(:overall_status) { "eligible" }

      it { is_expected.to include("Eligible") }
      it { is_expected.to include("govuk-tag--turquoise") }
    end

    context "when the overall status is 'payable'" do
      let(:overall_status) { "payable" }

      it { is_expected.to include("Payable") }
      it { is_expected.to include("govuk-tag--orange") }
    end

    context "when the overall status is 'paid'" do
      let(:overall_status) { "paid" }

      it { is_expected.to include("Paid") }
      it { is_expected.to include("govuk-tag--green") }
    end

    context "when the overall status is 'voided'" do
      let(:overall_status) { "voided" }

      it { is_expected.to include("Voided") }
      it { is_expected.to include("govuk-tag--red") }
    end

    context "when the overall status is 'awaiting_clawback'" do
      let(:overall_status) { "awaiting_clawback" }

      it { is_expected.to include("Awaiting clawback") }
      it { is_expected.to include("govuk-tag--pink") }
    end

    context "when the overall status is 'clawed_back'" do
      let(:overall_status) { "clawed_back" }

      it { is_expected.to include("Clawed back") }
      it { is_expected.to include("govuk-tag--purple") }
    end

    context "when the overall status is not recognised" do
      let(:overall_status) { "unknown_status" }

      it { is_expected.to include("unknown_status") }
      it { is_expected.to include("govuk-tag--grey") }
    end
  end

  describe "#declaration_event_state_name" do
    subject { helper.declaration_event_state_name(event) }

    let(:event) { instance_double(Event, event_type:, heading: "some heading") }

    context "when the event type is 'teacher_declaration_created'" do
      let(:event_type) { "teacher_declaration_created" }

      it { is_expected.to eq("Submitted") }
    end

    context "when the event type is 'teacher_declaration_voided'" do
      let(:event_type) { "teacher_declaration_voided" }

      it { is_expected.to eq("Voided") }
    end

    context "when the event type is 'teacher_declaration_clawed_back'" do
      let(:event_type) { "teacher_declaration_clawed_back" }

      it { is_expected.to eq("Clawed back") }
    end

    context "when the event type is not recognised" do
      let(:event_type) { "unknown_type" }

      it { is_expected.to eq("some heading") }
    end
  end

  describe "#declaration_course_identifier" do
    subject { helper.declaration_course_identifier(declaration) }

    context "when the declaration is for an ECT" do
      before { allow(declaration).to receive(:for_ect?).and_return(true) }

      it { is_expected.to eq("ecf-induction") }
    end

    context "when the declaration is for a mentor" do
      before do
        allow(declaration).to receive_messages(for_ect?: false, for_mentor?: true)
      end

      it { is_expected.to eq("ecf-mentor") }
    end
  end
end
