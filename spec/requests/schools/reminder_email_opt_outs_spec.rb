RSpec.describe "Schools::ReminderEmailOptOuts" do
  let(:school)      { FactoryBot.create(:school) }
  let(:token)       { "stub" }
  let(:token_valid) { true }

  before { allow(Schools::ReminderEmailOptOutToken).to receive(:valid?).and_return(token_valid) }

  shared_examples "checks the school id and token" do
    context "when the token is invalid" do
      let(:token_valid) { false }

      it "returns 404" do
        perform_request(school_id: school.id, token:)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the school id does not exist" do
      it "returns 404" do
        perform_request(school_id: 0, token:)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the school id is missing" do
      it "returns 404" do
        perform_request(token:)

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /school/opt-out-of-reminder-emails/new" do
    def perform_request(**params)
      get new_schools_reminder_email_opt_out_path, params:
    end

    include_examples "checks the school id and token"

    it "renders the confirmation page for a valid school id + token" do
      perform_request(school_id: school.id, token:)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Stop reminder emails for this term")
    end

    it "does not change the opted-out date" do
      expect {
        perform_request(school_id: school.id, token:)
      }.not_to(change { school.reload.opted_out_of_reminder_emails_until })
    end
  end

  describe "POST /school/opt-out-of-reminder-emails" do
    def perform_request(**params)
      post schools_reminder_email_opt_out_path, params:
    end

    include_examples "checks the school id and token"

    it "sets opted_out_of_reminder_emails_until to the end of the current term" do
      travel_to(Date.new(2026, 5, 19)) do
        perform_request(school_id: school.id, token:)

        expect(school.reload.opted_out_of_reminder_emails_until).to eq(Date.new(2026, 5, 31))
      end
    end

    it "renders the confirmation panel" do
      perform_request(school_id: school.id, token:)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("We will not send you reminder emails this term")
    end

    it "extends the opt-out when revisited in a new term" do
      travel_to(Date.new(2026, 5, 19)) do
        perform_request(school_id: school.id, token:)
      end

      travel_to(Date.new(2026, 6, 2)) do
        perform_request(school_id: school.id, token:)
        expect(school.reload.opted_out_of_reminder_emails_until).to eq(Date.new(2026, 12, 31))
      end
    end

    context "when the token is invalid" do
      let(:token_valid) { false }

      it "does not change the opted-out date" do
        perform_request(school_id: school.id, token:)

        expect(school.reload.opted_out_of_reminder_emails_until).to be_nil
      end
    end
  end
end
