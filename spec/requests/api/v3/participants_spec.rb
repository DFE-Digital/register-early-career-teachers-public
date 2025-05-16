RSpec.describe "Participants API", type: :request do
  describe "#index" do
    it "returns method not allowed" do
      api_get(api_v3_participants_path)
      expect(response).to be_method_not_allowed
    end
  end

  describe "#show" do
    it "returns method not allowed" do
      api_get(api_v3_participant_path(123))
      expect(response).to be_method_not_allowed
    end
  end

  describe "#change_schedule" do
    it "returns method not allowed" do
      api_put(api_v3_participant_change_schedule_path(123))
      expect(response).to be_method_not_allowed
    end
  end

  describe "#defer" do
    it "returns method not allowed" do
      api_put(api_v3_participant_defer_path(123))
      expect(response).to be_method_not_allowed
    end
  end

  describe "#resume" do
    it "returns method not allowed" do
      api_put(api_v3_participant_resume_path(123))
      expect(response).to be_method_not_allowed
    end
  end

  describe "#withdraw" do
    it "returns method not allowed" do
      api_put(api_v3_participant_withdraw_path(123))
      expect(response).to be_method_not_allowed
    end
  end
end
