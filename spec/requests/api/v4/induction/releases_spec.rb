RSpec.describe "API::V4::Induction::Releases", type: :request do
  let!(:golden_leaf) { FactoryBot.create(:appropriate_body_period, name: "Golden Leaf Teaching School Hub") }
  let(:teacher) { FactoryBot.create(:teacher) }

  context "with an ongoing induction period" do
    before do
      FactoryBot.create(:induction_period, :ongoing, teacher:, appropriate_body_period: golden_leaf, started_on: 1.year.ago.to_date)
    end

    it "closes the period as released and returns 200" do
      post(api_v4_release_path(trn: teacher.trn), params: { finished_on: 1.day.ago.to_date.iso8601, number_of_terms: 6 }, as: :json)

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["status"]).to eq("release")
      expect(body["finished_on"]).to eq(1.day.ago.to_date.iso8601)
      expect(teacher.reload.ongoing_induction_period).to be_nil
    end
  end

  context "when there is no ongoing induction period" do
    it "returns 404" do
      post(api_v4_release_path(trn: teacher.trn), params: { finished_on: 1.day.ago.to_date.iso8601, number_of_terms: 6 }, as: :json)

      expect(response).to have_http_status(:not_found)
    end
  end

  context "when the ongoing induction period belongs to another appropriate body" do
    let(:other_ab) { FactoryBot.create(:appropriate_body_period) }

    before do
      FactoryBot.create(:induction_period, :ongoing, teacher:, appropriate_body_period: other_ab, started_on: 1.year.ago.to_date)
    end

    it "returns 404 and does not close it" do
      post(api_v4_release_path(trn: teacher.trn), params: { finished_on: 1.day.ago.to_date.iso8601, number_of_terms: 6 }, as: :json)

      expect(response).to have_http_status(:not_found)
      expect(teacher.reload.ongoing_induction_period).to be_present
    end
  end
end
