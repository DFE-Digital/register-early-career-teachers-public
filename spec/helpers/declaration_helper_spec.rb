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
      it { is_expected.to include("govuk-tag--teal") }
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
      it { is_expected.to include("govuk-tag--magenta") }
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

    context "when the event type is 'teacher_declaration_awaiting_clawback'" do
      let(:event_type) { "teacher_declaration_awaiting_clawback" }

      it { is_expected.to eq("Awaiting clawback") }
    end

    context "when the event type is 'teacher_declaration_payable'" do
      let(:event_type) { "teacher_declaration_payable" }

      it { is_expected.to eq("Payable") }
    end

    context "when the event type is 'teacher_declaration_paid'" do
      let(:event_type) { "teacher_declaration_paid" }

      it { is_expected.to eq("Paid") }
    end

    context "when the event type is 'teacher_declaration_eligible'" do
      let(:event_type) { "teacher_declaration_eligible" }

      it { is_expected.to eq("Eligible") }
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

  describe "#declaration_voided_by_caption" do
    subject { helper.declaration_voided_by_caption(event) }

    let(:event) { instance_double(Event, event_type:, author_type:) }
    let(:author_type) { "dfe_staff_user" }

    context "when the event type is not a voided or clawed_back event" do
      let(:event_type) { "teacher_declaration_created" }

      it { is_expected.to be_nil }
    end

    context "when the event type is 'teacher_declaration_voided'" do
      let(:event_type) { "teacher_declaration_voided" }

      context "when voided by an admin user" do
        before { allow(event).to receive_messages(author_name: "Admin User", author_email: "admin@example.com") }

        it { is_expected.to include("Voided by Admin User (admin@example.com)") }
      end

      context "when voided by a lead provider" do
        let(:author_type) { "lead_provider_api" }

        it { is_expected.to include("Voided by lead provider") }
      end
    end

    context "when the event type is 'teacher_declaration_awaiting_clawback'" do
      let(:event_type) { "teacher_declaration_awaiting_clawback" }

      context "when clawed back by an admin user" do
        before { allow(event).to receive_messages(author_name: "Finance User", author_email: "finance@example.com") }

        it { is_expected.to include("Voided by Finance User (finance@example.com)") }
      end

      context "when clawed back by a lead provider" do
        let(:author_type) { "lead_provider_api" }

        it { is_expected.to include("Voided by lead provider") }
      end
    end

    context "when the author has been deleted" do
      let(:event_type) { "teacher_declaration_voided" }
      let(:author) { FactoryBot.create(:user) }
      let!(:event) do
        FactoryBot.create(
          :event,
          event_type:,
          author:,
          author_type:,
          author_name: "Deleted User",
          author_email: "deleted@example.com"
        )
      end

      before { author.destroy! }

      it "uses the event snapshots after the author id is nullified" do
        expect(event.reload.author_id).to be_nil
        expect(subject).to include("Voided by Deleted User (deleted@example.com)")
      end
    end

    context "when the live author's details have changed" do
      let(:event_type) { "teacher_declaration_awaiting_clawback" }
      let(:author) { FactoryBot.create(:user) }
      let!(:event) do
        FactoryBot.create(
          :event,
          event_type:,
          author:,
          author_type:,
          author_name: "Deleted User",
          author_email: "deleted@example.com"
        )
      end

      before do
        author.update!(name: "Updated User", email: "updated@education.gov.uk")
      end

      it { is_expected.to include("Voided by Deleted User (deleted@example.com)") }
    end
  end
end
