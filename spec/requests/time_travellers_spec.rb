RSpec.describe "Time Travellers", type: :request do
  before do
    allow(Rails.application.config)
      .to receive(:enable_time_travel)
      .and_return(true)
  end

  describe "GET #new" do
    subject(:new_time_traveller) do
      get new_time_traveller_path
      response
    end

    it { is_expected.to have_http_status(:ok) }
  end

  describe "POST #create" do
    subject(:create_time_traveller) do
      post(time_traveller_path, params:)
      response
    end

    context "when the date is valid" do
      let(:params) do
        {
          time_traveller: {
            "travel_to(1i)": "2025",
            "travel_to(2i)": "12",
            "travel_to(3i)": "25"
          }
        }
      end

      it { is_expected.to redirect_to(root_path) }

      it "assigns the date after time travel to the session" do
        create_time_traveller
        expect(session["date_after_time_travel"]).to eq(Date.new(2025, 12, 25))
      end
    end

    context "when the date is invalid" do
      let(:params) do
        {
          time_traveller: {
            "travel_to(1i)": "2025",
            "travel_to(2i)": "12",
            "travel_to(3i)": ""
          }
        }
      end

      it { is_expected.to have_http_status(:unprocessable_content) }

      it "does not assign a date after time travel to the session" do
        create_time_traveller
        expect(session["date_after_time_travel"]).to be_nil
      end
    end

    context "when the date is in the wrong format" do
      let(:params) do
        {
          time_traveller: {
            "travel_to(1i)": "2025",
            "travel_to(2i)": "23",
            "travel_to(3i)": "1"
          }
        }
      end

      it { is_expected.to have_http_status(:unprocessable_content) }

      it "does not assign a date after time travel to the session" do
        create_time_traveller
        expect(session["date_after_time_travel"]).to be_nil
      end
    end
  end

  describe "DELETE #destroy" do
    subject(:destroy_time_traveller) do
      delete(time_traveller_path)
      response
    end

    it { is_expected.to redirect_to(root_path) }

    it "removes the date after time travel from the session" do
      post time_traveller_path, params: {
        time_traveller: {
          "travel_to(1i)": "2025",
          "travel_to(2i)": "12",
          "travel_to(3i)": "25"
        }
      }
      expect(session["date_after_time_travel"]).to eq(Date.new(2025, 12, 25))

      destroy_time_traveller
      expect(session["date_after_time_travel"]).to be_nil
    end
  end
end
