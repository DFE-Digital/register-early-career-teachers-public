RSpec.describe "API::V4::Induction::Passes", type: :request do
  let!(:golden_leaf) { FactoryBot.create(:appropriate_body_period, name: "Golden Leaf Teaching School Hub") }
  let(:teacher) { FactoryBot.create(:teacher) }

  before do
    FactoryBot.create(:induction_period, :ongoing, teacher:, appropriate_body_period: golden_leaf, started_on: 1.year.ago.to_date)
  end

  it "closes the period with a pass outcome and returns 200" do
    post(api_v4_pass_path(trn: teacher.trn), params: { finished_on: 1.day.ago.to_date.iso8601, number_of_terms: 6 }, as: :json)

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["status"]).to eq("pass")
    expect(teacher.reload.induction_periods.last).to have_attributes(outcome: "pass", number_of_terms: 6)
  end
end
