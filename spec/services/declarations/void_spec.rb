RSpec.describe Declarations::Void do
  subject(:instance) do
    described_class.new(author:, declaration:, voided_by_user_id:)
  end

  let(:declaration) { FactoryBot.create(:declaration, :payable) }
  let(:author) do
    lead_provider = declaration.training_period.lead_provider
    Events::LeadProviderAPIAuthor.new(lead_provider:)
  end
  let(:voided_by_user_id) { FactoryBot.create(:user).id }

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
      expect(Events::Record)
        .to receive(:record_teacher_declaration_voided!)
        .with(
          author:,
          teacher: declaration.training_period.teacher,
          training_period: declaration.training_period,
          declaration:
        )

      void
    end

    context "when there is a voided_by_user_id" do
      it "assigns the voided_by_user" do
        expect { void }
          .to change(declaration, :voided_by_user_id)
          .to(voided_by_user_id)
      end

      it "touches the voided_by_user_at timestamp" do
        freeze_time

        expect { void }
          .to change(declaration, :voided_by_user_at)
          .to(Time.current)
      end
    end

    context "when there is no voided_by_user_id" do
      let(:voided_by_user_id) { nil }

      it "does not assign the voided_by_user" do
        expect { void }.not_to(change(declaration, :voided_by_user_id))
      end

      it "does not touch the voided_by_user_at timestamp" do
        expect { void }.not_to(change(declaration, :voided_by_user_at))
      end
    end
  end
end
