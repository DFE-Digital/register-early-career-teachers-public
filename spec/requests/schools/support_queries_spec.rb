describe "Schools::SupportQueriesController", :enable_schools_interface do
  let(:current_user) { FactoryBot.create(:school_user, :at_random_school) }

  before do
    first_name, last_name = current_user.name.split(" ", 2)

    sign_in_as(
      :school_user,
      school: current_user.school,
      email: current_user.email,
      first_name:,
      last_name:
    )
  end

  describe "GET #new" do
    it "renders" do
      get new_schools_support_query_path

      expect(response).to be_successful
      expect(response.body).to include("Get help with registering early career teachers")
    end
  end

  describe "POST #create" do
    let(:request) { post schools_support_queries_path, params: { support_query: { message: } } }

    context "with a message" do
      let(:message) { "Hello, world!" }
      let(:created_support_query) { SupportQuery.last }

      it "creates a new support query" do
        assert_difference -> { SupportQuery.count } do
          request
        end

        assert_equal current_user.name, created_support_query.name
        assert_equal current_user.email, created_support_query.email
        assert_equal current_user.school.name, created_support_query.school_name
        assert_equal current_user.school.urn, created_support_query.school_urn
        assert_equal message, created_support_query.message
      end

      it "enqueues a job to send the support query to Zendesk" do
        expect { request }.to have_enqueued_job(SupportQuery::SendToZendeskJob).with(created_support_query)
      end

      it "renders the success message" do
        request

        expect(response).to be_successful
        expect(response.body).to include("Your request for help has been submitted")
      end
    end

    context "without a message" do
      let(:message) { "" }

      it "does not create a new support query and renders error message" do
        assert_no_difference -> { SupportQuery.count } do
          request
        end

        expect(response).to be_successful
        expect(response.body).to include("Enter your message")
      end
    end
  end
end
