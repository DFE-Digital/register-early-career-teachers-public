RSpec.describe Backfill::RecordDeclarationVoidEvent do
  subject(:process) { described_class.new(declaration:).process }

  let(:user) { FactoryBot.create(:user, :finance) }
  let(:voided_at) { 2.months.ago.change(usec: 0) }
  let!(:declaration) do
    FactoryBot.create(:declaration, :voided_by_user, voided_by_user: user, voided_by_user_at: voided_at)
  end

  describe "#process" do
    it "records the original void action with the users details" do
      expect { process }.to change(Event, :count).by(1)

      expect(declaration.events.sole).to have_attributes(
        event_type: "teacher_declaration_voided",
        heading: "#{declaration.teacher.full_name}’s declaration was voided",
        body: "The declaration was voided on the date shown. " \
              "This timeline entry was added retrospectively using the details already recorded on the declaration.",
        happened_at: voided_at,
        declaration:,
        teacher: declaration.teacher,
        training_period: declaration.training_period,
        author_id: user.id,
        author_name: user.name,
        author_email: user.email,
        author_type: "dfe_staff_user"
      )
    end

    it "returns true when it creates an event" do
      expect(process).to be(true)
    end

    it "does not change the declaration" do
      expect { process }
        .not_to(change { declaration.reload.attributes })
    end

    context "when the backfill is run again" do
      before { described_class.new(declaration:).process }

      it "does not create duplicate events" do
        expect { process }.not_to change(Event, :count)
      end

      it "returns false" do
        expect(process).to be(false)
      end
    end

    context "when the void event already exists" do
      let!(:event) do
        FactoryBot.create(
          :event,
          declaration:,
          event_type: "teacher_declaration_voided",
          author_id: user.id,
          author_name: user.name,
          author_email: user.email,
          author_type: "dfe_staff_user"
        )
      end

      it "preserves the existing event" do
        original_attributes = event.attributes

        expect { process }.not_to change(Event, :count)

        expect(process).to be(false)
        expect(event.reload.attributes).to eq(original_attributes)
      end
    end

    %i[awaiting_clawback clawed_back].each do |status|
      context "when the declaration is #{status}" do
        let(:declaration) do
          FactoryBot.create(:declaration, :voided_by_user, status, voided_by_user: user, voided_by_user_at: voided_at)
        end

        it "records who initiated the clawback at the original action time" do
          expect(process).to be(true)

          expect(declaration.events.sole).to have_attributes(
            event_type: "teacher_declaration_awaiting_clawback",
            heading: "#{declaration.teacher.full_name}’s declaration was marked as awaiting clawback",
            body: "The declaration was marked as awaiting clawback on the date shown. " \
                  "This timeline entry was added retrospectively using the details already recorded on the declaration.",
            happened_at: voided_at,
            teacher: declaration.teacher,
            training_period: declaration.training_period,
            author_id: user.id,
            author_name: user.name,
            author_email: user.email,
            author_type: "dfe_staff_user"
          )
        end

        it "does not duplicate an existing clawback initiation event" do
          FactoryBot.create(:event, declaration:, event_type: "teacher_declaration_awaiting_clawback")

          expect { process }.not_to change(Event, :count)

          expect(process).to be(false)
        end
      end
    end

    context "when payment and clawback completion events already exist" do
      let(:declaration) do
        FactoryBot.create(:declaration, :voided_by_user, :clawed_back, voided_by_user: user, voided_by_user_at: voided_at)
      end

      it "adds the user's action without changing the system events" do
        system_events = %w[teacher_declaration_paid teacher_declaration_clawed_back].map do |event_type|
          FactoryBot.create(:event, declaration:, event_type:, author_type: "system", author_name: "System")
        end
        original_attributes = system_events.map(&:attributes)

        expect { process }.to change(Event, :count).by(1)

        expect(system_events.map { it.reload.attributes }).to eq(original_attributes)
        expect(declaration.events.where(event_type: "teacher_declaration_awaiting_clawback").sole.author_id).to eq(user.id)
      end
    end

    context "when the declaration has not been voided or clawed back" do
      let(:declaration) { FactoryBot.create(:declaration, :no_payment) }

      it "rejects the declaration without creating an event" do
        expect { process }.to raise_error(ArgumentError, "Declaration must be voided, awaiting clawback or clawed back")

        expect(declaration.events).to be_empty
      end
    end
  end
end
