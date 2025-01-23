require "rails_helper"

RSpec.describe "Partnerships API", type: :request do
  describe "#create" do
    it "returns method not allowed" do
      post api_v3_partnerships_path
      expect(response).to be_method_not_allowed
    end
  end

  describe "#index" do
    it "returns method not allowed" do
      get api_v3_partnerships_path
      expect(response).to be_method_not_allowed
    end
  end

  describe "#show" do
    it "returns method not allowed" do
      get api_v3_partnership_path(123)
      expect(response).to be_method_not_allowed
    end
  end

  describe "#update" do
    it "returns method not allowed" do
      put api_v3_partnership_path(123)
      expect(response).to be_method_not_allowed
    end
  end
end
