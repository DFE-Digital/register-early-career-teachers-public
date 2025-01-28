require "rails_helper"

RSpec.describe "Delivery partners API", type: :request do
  describe "#index" do
    it "returns method not allowed" do
      get api_v3_delivery_partners_path
      expect(response).to be_method_not_allowed
    end
  end

  describe "#show" do
    it "returns method not allowed" do
      get api_v3_delivery_partner_path(123)
      expect(response).to be_method_not_allowed
    end
  end
end
