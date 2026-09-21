RSpec.describe Admin::Users::RemoveUserForm do
  subject(:form) do
    described_class.new(
      user:,
      author:,
      confirmed:
    )
  end

  let!(:user) { FactoryBot.create(:user) }
  let!(:author_user) { FactoryBot.create(:user, :user_manager) }
  let(:author) { Sessions::Users::DfEPersona.new(email: author_user.email) }
  let(:confirmed) { true }

  describe "#save" do
    it "removes the user when confirmed" do
      expect {
        form.save
      }.to change(User, :count).by(-1)

      expect(User.exists?(user.id)).to be(false)
    end

    it "passes the author and user to the removal service" do
      dfe_users = instance_double(Admin::DfEUsers)

      allow(Admin::DfEUsers)
        .to receive(:new)
        .with(author:)
        .and_return(dfe_users)

      allow(dfe_users)
        .to receive(:remove_user)
        .with(user.id)

      expect(form.save).to be(true)

      expect(dfe_users).to have_received(:remove_user).with(user.id)
    end

    context "when confirmation is missing" do
      let(:confirmed) { nil }

      it "does not remove the user" do
        expect {
          form.save
        }.not_to change(User, :count)
      end

      it "returns false and adds the confirmation error" do
        expect(form.save).to be(false)

        expect(form.errors[:confirmed]).to include(
          "Confirm you want to remove #{user.name} as a user"
        )
      end

      it "does not call the removal service" do
        allow(Admin::DfEUsers).to receive(:new)

        form.save

        expect(Admin::DfEUsers).not_to have_received(:new)
      end
    end
  end
end
