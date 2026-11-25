RSpec.describe Declarations::Void do
  subject(:instance) do
    described_class.new(author:, declaration:)
  end

  let(:declaration) { FactoryBot.create(:declaration, :payable) }
  let(:author) do
    lead_provider = declaration.training_period.lead_provider
    Events::LeadProviderAPIAuthor.new(lead_provider:)
  end

  describe "#void" do
    subject(:void) { instance.void }

    it "voids the declaration" do
      expect { void }
        .to change(declaration, :payment_status)
        .from("payable")
        .to("voided")
    end

    it "completes the mentor" do
      mentor_completion_service = instance_double(Declarations::MentorCompletion)
      allow(Declarations::MentorCompletion)
        .to receive(:new)
        .with(author:, declaration:)
        .and_return(mentor_completion_service)

      expect(mentor_completion_service).to receive(:perform).once

      void
    end

    it "records an event" do
      void

      expect(Event.where(event_type: "teacher_declaration_voided").sole)
        .to have_attributes(
          teacher_id: declaration.training_period.teacher.id,
          training_period_id: declaration.training_period.id,
          declaration_id: declaration.id
        )
    end

    context "when the author is a DfE user" do
      let(:author) { Sessions::Users::DfEPersona.new(email: FactoryBot.create(:user).email) }

      it "records the author details on the event" do
        freeze_time

        void

        expect(declaration.events.sole).to have_attributes(
          author_id: author.id,
          author_name: author.name,
          author_email: author.email,
          author_type: "dfe_staff_user",
          happened_at: Time.current
        )
      end
    end

    context "when declaration is `voided`" do
      let(:declaration) { FactoryBot.create(:declaration, :voided) }

      it "raises an error" do
        expect {
          void
        }.to raise_error(StateMachines::InvalidTransition)
      end
    end

    context "when declaration is `paid`" do
      let(:declaration) { FactoryBot.create(:declaration, :paid) }

      it "raises an error" do
        expect {
          void
        }.to raise_error(StateMachines::InvalidTransition)
      end
    end

    Declaration::VOIDABLE_PAYMENT_STATUSES.each do |status|
      context "when declaration is `#{status}`" do
        let(:declaration) { FactoryBot.create(:declaration, :"#{status}") }

        it "voids the declaration" do
          expect { void }
            .to change(declaration, :payment_status)
            .from(status)
            .to("voided")
        end
      end
    end
  end
end
