RSpec.describe Declarations::Clawback do
  subject(:instance) do
    described_class.new(
      author:,
      declaration:
    )
  end

  let(:declaration) do
    FactoryBot.create(:declaration, :paid,
                      framework_agreement: FactoryBot.create(:framework_agreement, contract_period: FactoryBot.create(:contract_period, :previous)))
  end
  let(:author) { Events::LeadProviderAPIAuthor.new(lead_provider:) }

  let(:lead_provider) { declaration.training_period.lead_provider }
  let(:contract_period) { declaration.training_period.contract_period }
  let(:framework_agreement) { FactoryBot.create(:framework_agreement, lead_provider:, contract_period:) }
  let!(:next_available_output_fee_statement) do
    FactoryBot.create(:statement, :output_fee, framework_agreement:,
                                               month: 1.month.from_now.month,
                                               year: 1.month.from_now.year,
                                               deadline_date: 1.month.from_now.to_date,
                                               payment_date: 2.months.from_now.to_date)
  end

  before do
    # make payment statement precede clawback statement, avoiding
    # validation rules around deadline_date.
    declaration.payment_statement.update_columns(deadline_date: Date.yesterday, payment_date: Date.current)
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
      clawback

      expect(Event.where(event_type: "teacher_declaration_awaiting_clawback").sole)
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

        expect { clawback }
          .not_to(change { declaration.reload.attributes.slice("voided_by_user_id", "voided_by_user_at") })

        expect(declaration.events.sole).to have_attributes(
          author_id: author.id,
          author_name: author.name,
          author_email: author.email,
          author_type: "dfe_staff_user",
          happened_at: Time.current
        )
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
