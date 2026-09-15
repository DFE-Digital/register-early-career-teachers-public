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
  end
end
