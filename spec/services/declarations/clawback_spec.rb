RSpec.describe Declarations::Clawback do
  subject(:instance) do
    described_class.new(
      author:,
      declaration:,
      voided_by_user_id:
    )
  end

  let(:declaration) { FactoryBot.create(:declaration, :paid) }
  let(:author) { Events::LeadProviderAPIAuthor.new(lead_provider:) }
  let(:voided_by_user_id) { FactoryBot.create(:user).id }

  let(:lead_provider) { declaration.training_period.lead_provider }
  let(:contract_period) { declaration.training_period.contract_period }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:, contract_period:) }
  let!(:next_available_output_fee_statement) { FactoryBot.create(:statement, :output_fee, active_lead_provider:) }

  before do
    # make payment statement precede clawback statement
    declaration.payment_statement.update!(deadline_date: Date.yesterday)
  end

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
        .to receive(:record_teacher_declaration_awaiting_clawback!)
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

    context "when there is no next available output fee statement" do
      before do
        next_available_output_fee_statement.destroy!
        instance.clawback
      end

      it "is invalid" do
        expect(instance).to have_error(:next_available_output_fee_statement)
      end

      it "does not clawback the declaration" do
        expect(declaration.clawback_status).to eq("no_clawback")
      end
    end
  end
end
