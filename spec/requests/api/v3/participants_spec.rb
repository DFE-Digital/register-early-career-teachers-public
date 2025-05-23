RSpec.describe "Participants API", type: :request do
  describe "#index" do
    let(:path) { api_v3_participants_path }

    it_behaves_like "a token authenticated endpoint", :get

    it "returns method not allowed" do
      authenticated_api_get path
      expect(response).to be_method_not_allowed
    end
  end

  describe "#show" do
    let(:path) { api_v3_participant_path(123) }

    it_behaves_like "a token authenticated endpoint", :get

    it "returns method not allowed" do
      authenticated_api_get path
      expect(response).to be_method_not_allowed
    end
  end

  describe "#change_schedule" do
    let(:path) { api_v3_participant_change_schedule_path(123) }

    it_behaves_like "a token authenticated endpoint", :put

    it "returns method not allowed" do
      authenticated_api_put path
      expect(response).to be_method_not_allowed
    end
  end

  describe "#defer" do
    let(:path) { api_v3_participant_defer_path(123) }

    it_behaves_like "a token authenticated endpoint", :put

    it "returns method not allowed" do
      authenticated_api_put path
      expect(response).to be_method_not_allowed
    end
  end

  describe "#resume" do
    let(:path) { api_v3_participant_resume_path(123) }

    it_behaves_like "a token authenticated endpoint", :put

    it "returns method not allowed" do
      authenticated_api_put path
      expect(response).to be_method_not_allowed
    end
  end

  describe "#withdraw" do
    let(:path) { api_v3_participant_withdraw_path(123) }

    it_behaves_like "a token authenticated endpoint", :put

    it "returns method not allowed" do
      authenticated_api_put path
      expect(response).to be_method_not_allowed
    end
  end
end
