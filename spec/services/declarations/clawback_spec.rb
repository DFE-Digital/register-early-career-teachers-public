RSpec.describe Declarations::Clawback do
  subject(:instance) do
    described_class.new(
      author:,
      declaration:,
      voided_by_user_id:,
      next_available_output_fee_statement:
    )
  end

  let(:declaration) { FactoryBot.create(:declaration, :paid) }
  let(:author) do
    lead_provider = declaration.training_period.lead_provider
    Events::LeadProviderAPIAuthor.new(lead_provider:)
  end
  let(:voided_by_user_id) { FactoryBot.create(:user).id }
  let(:next_available_output_fee_statement) { declaration.payment_statement }

  describe "#clawback" do
    subject(:clawback) { instance.clawback }

    it "starts clawing back the declaration" do
      expect { clawback }
        .to change(declaration, :clawback_status)
        .from("no_clawback")
        .to("awaiting_clawback")
    end

    it "attaches a clawback statement to the next output fee statement" do
      expect { clawback }
        .to change(declaration, :clawback_statement)
        .from(nil)
        .to(next_available_output_fee_statement)
    end

    it "completes the mentor" do
      mentor_completion_service = instance_double(Declarations::MentorCompletion)
      allow(Declarations::MentorCompletion)
        .to receive(:new)
        .with(author:, declaration:)
        .and_return(mentor_completion_service)

      expect(mentor_completion_service).to receive(:perform).once

      clawback
    end

    it "records an event" do
      expect(Events::Record)
        .to receive(:record_teacher_declaration_clawed_back!)
        .with(
          author:,
          teacher: declaration.training_period.teacher,
          training_period: declaration.training_period,
          declaration:
        )

      clawback
    end

    context "when there is a voided_by_user_id" do
      it "assigns the voided_by_user" do
        expect { clawback }
          .to change(declaration, :voided_by_user_id)
          .to(voided_by_user_id)
      end

      it "touches the voided_by_user_at timestamp" do
        freeze_time

        expect { clawback }
          .to change(declaration, :voided_by_user_at)
          .to(Time.current)
      end
    end

    context "when there is no voided_by_user_id" do
      let(:voided_by_user_id) { nil }

      it "does not assign the voided_by_user" do
        expect { clawback }.not_to(change(declaration, :voided_by_user_id))
      end

      it "does not touch the voided_by_user_at timestamp" do
        expect { clawback }.not_to(change(declaration, :voided_by_user_at))
      end
    end
  end
end
