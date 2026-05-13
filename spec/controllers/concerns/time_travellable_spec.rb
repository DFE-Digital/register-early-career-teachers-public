RSpec.describe TimeTravellable, type: :controller do
  controller(ActionController::Base) do
    include TimeTravellable

    def show
      render plain: "It's #{Date.current.strftime('%Y-%m-%d')}"
    end
  end

  before do
    routes.draw { get "show" => "anonymous#show" }
    allow(Rails.application.config)
      .to receive(:enable_time_travel)
      .and_return(time_travel_enabled)
  end

  let!(:todays_date) { Date.current }

  context "when time travel is enabled" do
    let(:time_travel_enabled) { true }

    context "when the date after time travel is set in the session" do
      let(:session) { { "date_after_time_travel" => "2025-12-25" } }

      it "returns the time-travelled date" do
        get(:show, session:)

        expect(response.body).to eq("It's 2025-12-25")
      end
    end

    context "when the date after time travel is not set in the session" do
      let(:session) { {} }

      it "returns the non-time-travelled date" do
        get(:show, session:)

        expect(response.body).to eq("It's #{todays_date.strftime('%Y-%m-%d')}")
      end
    end
  end

  context "when time travel is disabled" do
    let(:time_travel_enabled) { false }

    context "when the date after time travel is set in the session" do
      let(:session) { { "date_after_time_travel" => "2025-12-25" } }

      it "returns the non-time-travelled date" do
        get(:show, session:)

        expect(response.body).to eq("It's #{todays_date.strftime('%Y-%m-%d')}")
      end
    end

    context "when the date after time travel is not set in the session" do
      let(:session) { {} }

      it "returns the non-time-travelled date" do
        get(:show, session:)

        expect(response.body).to eq("It's #{todays_date.strftime('%Y-%m-%d')}")
      end
    end
  end
end
