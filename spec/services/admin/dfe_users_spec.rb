RSpec.describe Admin::DfEUsers do
  describe "#remove_user" do
    subject(:remove_user) { described_class.new(author:).remove_user(user.id) }

    let!(:author_user) { FactoryBot.create(:user, :user_manager) }
    let(:author) { Sessions::Users::DfEPersona.new(email: author_user.email) }

    let!(:user) do
      FactoryBot.create(
        :user,
        name: "Daphne Blake",
        email: "daphne.blake@education.gov.uk",
        role: :admin
      )
    end

    before do
      allow(Events::Record)
        .to receive(:record_dfe_user_deleted_event!)
        .and_call_original
    end

    it "removes the user" do
      expect { remove_user }
        .to change(User, :count).by(-1)
    end

    it "records the deletion event" do
      remove_user

      expect(Events::Record)
        .to have_received(:record_dfe_user_deleted_event!)
        .with(
          author:,
          user_name: user.name,
          user_email: user.email,
          user_role: user.role
        )
    end

    it "preserves existing events for the removed user" do
      event = FactoryBot.create(:event, user:)

      remove_user

      expect(Event.exists?(event.id)).to be(true)
      expect(event.reload.user_id).to be_nil
    end

    it "preserves events authored by the removed user" do
      event = FactoryBot.create(:event, author_id: user.id)

      remove_user

      expect(Event.exists?(event.id)).to be(true)
      expect(event.reload.author_id).to be_nil
    end

    context "when the author tries to remove themselves" do
      let(:author) { Sessions::Users::DfEPersona.new(email: user.email) }

      it "does not remove the user" do
        expect {
          expect { remove_user }
            .to raise_error(Admin::DfEUsers::CannotRemoveSelfError)
        }.not_to change(User, :count)
      end

      it "does not record a deletion event" do
        expect { remove_user }
          .to raise_error(Admin::DfEUsers::CannotRemoveSelfError)

        expect(Events::Record)
          .not_to have_received(:record_dfe_user_deleted_event!)
      end
    end

    %i[voided awaiting_clawback clawed_back].each do |status|
      context "when the user previously voided a declaration that is #{status}" do
        let(:voided_at) { 2.months.ago.change(usec: 0) }
        let!(:declaration) { FactoryBot.create(:declaration, status) }
        let!(:event) do
          FactoryBot.create(
            :event,
            event_type: status == :voided ? "teacher_declaration_voided" : "teacher_declaration_awaiting_clawback",
            happened_at: voided_at,
            declaration:,
            teacher: declaration.teacher,
            training_period: declaration.training_period,
            author: user,
            author_name: user.name,
            author_email: user.email,
            author_type: "dfe_staff_user"
          )
        end

        it "removes the user without changing the declaration or historical attribution" do
          declaration_attributes = declaration.attributes
          event_attributes = event.attributes

          expect { remove_user }
            .to change(User, :count).by(-1)

          expect(declaration.reload.attributes).to eq(declaration_attributes)
          expect(declaration).to be_valid
          expect(event.reload.author_id).to be_nil
          expect(event.attributes.except("author_id")).to eq(event_attributes.except("author_id"))
        end
      end
    end

    context "when the user cannot be destroyed" do
      before do
        allow(User).to receive(:find).with(user.id).and_return(user)
        allow(user).to receive(:destroy!).and_raise(ActiveRecord::RecordNotDestroyed)
      end

      it "does not remove the user" do
        expect {
          expect { remove_user }
            .to raise_error(ActiveRecord::RecordNotDestroyed)
        }.not_to change(User, :count)
      end

      it "does not record a deletion event" do
        expect { remove_user }
          .to raise_error(ActiveRecord::RecordNotDestroyed)

        expect(Events::Record)
          .not_to have_received(:record_dfe_user_deleted_event!)
      end
    end
  end
end
