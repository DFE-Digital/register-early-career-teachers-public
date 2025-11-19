describe "Admin::Users" do
  include_context "sign in as DfE user"

  before do
    allow(Events::Record).to receive(:record_dfe_user_created_event!).with(any_args).and_call_original
    allow(Events::Record).to receive(:record_dfe_user_updated_event!).with(any_args).and_call_original
  end

  describe "GET /admin/users" do
    let!(:users) { FactoryBot.create_list(:user, 2) }

    before { allow(User).to receive(:alphabetical).and_call_original }

    it "retuns a list of admin users in alphabetical order" do
      get admin_users_path
      expect(User).to have_received(:alphabetical)
    end

    it "displays the user names on the page" do
      get admin_users_path
      expect(response.body).to include(*users.map(&:name))
    end
  end

  describe "GET /admin/users/new" do
    before { allow(User).to receive(:new).and_call_original }

    it "finds the requested user" do
      get new_admin_user_path
      expect(User).to have_received(:new).once
    end
  end

  describe "POST /admin/users" do
    let(:user_params) { FactoryBot.attributes_for(:user) }

    it "creates a new user record and records an event" do
      post admin_users_path, params: { user: user_params }

      aggregate_failures do
        expect(User.where(email: user_params.fetch(:email))).to exist
        expect(Events::Record).to have_received(:record_dfe_user_created_event!).once
      end
    end

    it "uses the DfEUsers service to create the user" do
      fake_dfe_users_object = double(Admin::DfEUsers, create_user: true, user: double(User, name: "joey"))
      allow(Admin::DfEUsers).to receive(:new).and_return(fake_dfe_users_object)
      post admin_users_path, params: { user: user_params }
      expect(fake_dfe_users_object).to have_received(:create_user).with(hash_including(user_params))
    end

    context "with an invalid submission" do
      it "does not creates a new user record and does not try to create an event" do
        post admin_users_path, params: { user: user_params.except(:email) }
        expect(response).to be_bad_request
        expect(Events::Record).not_to have_received(:record_dfe_user_created_event!)
      end
    end
  end

  describe "GET /admin/users/:id" do
    let!(:user) { FactoryBot.create(:user) }

    before { allow(User).to receive(:find).and_call_original }

    it "finds the requested user" do
      get admin_user_path(user)
      expect(User).to have_received(:find).with(user.id.to_s)
    end

    it "shows the user details on the page" do
      get admin_user_path(user)
      expect(response.body).to include(user.name)
    end
  end

  describe "GET /admin/users/:id/edit" do
    let!(:user) { FactoryBot.create(:user) }

    before { allow(User).to receive(:find).and_call_original }

    it "finds the requested user" do
      get edit_admin_user_path(user)
      expect(User).to have_received(:find).with(user.id.to_s)
    end

    it "shows the user details on the page" do
      get admin_user_path(user)
      expect(response.body).to include(user.name)
    end
  end

  describe "PATCH /admin/users" do
    let(:user) { FactoryBot.create(:user) }
    let(:new_email_address) { "joey@example.com" }
    let(:update_user_params) { { email: new_email_address } }

    it "updates the user record and records an event" do
      patch admin_user_path(user), params: { user: update_user_params }

      aggregate_failures do
        expect(User.where(email: new_email_address)).to exist
        expect(Events::Record).to have_received(:record_dfe_user_updated_event!).once
      end
    end

    it "uses the DfEUsers service to update the user" do
      fake_dfe_users_object = double(Admin::DfEUsers, update_user: true, user:)
      allow(Admin::DfEUsers).to receive(:new).and_return(fake_dfe_users_object)
      patch admin_user_path(user), params: { user: update_user_params }
      expect(fake_dfe_users_object).to have_received(:update_user).with(user.id.to_s, hash_including(update_user_params))
    end

    context "with an invalid submission and does not try to create an event" do
      it "does not creates a new user record and redirects" do
        patch admin_user_path(user), params: { user: update_user_params.merge(email: "") }

        aggregate_failures do
          expect(response).to be_bad_request
          expect(Events::Record).not_to have_received(:record_dfe_user_updated_event!)
        end
      end
    end
  end
end
