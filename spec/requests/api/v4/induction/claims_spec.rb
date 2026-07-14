RSpec.describe "API::V4::Induction::Claims", type: :request do
  let!(:golden_leaf) { FactoryBot.create(:appropriate_body_period, name: "Golden Leaf Teaching School Hub") }
  let(:trn) { "3002586" }

  context "when the teacher can be claimed" do
    include_context "test TRS API returns a teacher"

    it "creates an ongoing induction period and returns 201" do
      expect {
        post api_v4_claim_path(trn:), params: {
          date_of_birth: "1990-01-01",
          started_on: 6.months.ago.to_date.iso8601,
          training_programme: "school_led"
        }, as: :json
      }.to change(InductionPeriod, :count).by(1)

      expect(response).to have_http_status(:created)
      body = response.parsed_body
      expect(body["trn"]).to eq(trn)
      expect(body["status"]).to eq("ongoing")
      expect(body["training_programme"]).to eq("school_led")
    end
  end

  context "when no teacher is found in TRS" do
    include_context "test TRS API returns nothing"

    it "returns 404" do
      post api_v4_claim_path(trn:), params: {
        date_of_birth: "1990-01-01",
        started_on: 6.months.ago.to_date.iso8601,
        training_programme: "school_led"
      }, as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  context "when the teacher is already claimed by another appropriate body" do
    include_context "test TRS API returns a teacher"

    let(:other_ab) { FactoryBot.create(:appropriate_body_period) }
    let(:teacher) { FactoryBot.create(:teacher, trn:) }

    before do
      FactoryBot.create(:induction_period, :ongoing, teacher:, appropriate_body_period: other_ab, started_on: Date.parse("2 October 2022"))
    end

    it "returns 409 and does not create a period" do
      expect {
        post api_v4_claim_path(trn:), params: {
          date_of_birth: "1990-01-01",
          started_on: 6.months.ago.to_date.iso8601,
          training_programme: "school_led"
        }, as: :json
      }.not_to change(InductionPeriod, :count)

      expect(response).to have_http_status(:conflict)
    end
  end

  context "when the induction start date is before the QTS award date" do
    include_context "test TRS API returns a teacher"

    it "returns 422" do
      post api_v4_claim_path(trn:), params: {
        date_of_birth: "1990-01-01",
        started_on: "2021-10-01",
        training_programme: "school_led"
      }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
