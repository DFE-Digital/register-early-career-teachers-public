RSpec.describe "POST /api/induction/v1/teachers/:trn/pass", type: :request do
  let(:appropriate_body_period) { FactoryBot.create(:appropriate_body_period, name: "Golden Leaf Teaching School Hub") }
  let(:authorization) { FactoryBot.create(:api_oauth_authorization, :with_token, appropriate_body_period:) }
  let(:teacher) { FactoryBot.create(:teacher, :with_name) }
  let!(:induction_period) { FactoryBot.create(:induction_period, :unfinished, teacher:, appropriate_body_period:) }
  let(:trn) { teacher.trn }
  let(:passed_on) { 1.day.ago.to_date }
  let(:params) { { passed_on: passed_on.iso8601, number_of_terms: 3 } }

  def pass(params: self.params, headers: bearer_auth_headers(authorization:))
    post("/api/induction/v1/teachers/#{trn}/pass", params:, headers:, as: :json)
  end

  it "passes the ECT's induction" do
    pass

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq(
      "trn" => trn,
      "full_name" => "John Keating",
      "passed_on" => passed_on.iso8601,
      "number_of_terms" => 3.0
    )
    expect(induction_period.reload).to have_attributes(finished_on: passed_on, number_of_terms: 3, outcome: "pass")
    expect(Event.where(event_type: "teacher_passes_induction").sole).to have_attributes(
      author_type: "appropriate_body_api",
      author_name: "Golden Leaf Teaching School Hub",
      heading: "John Keating passed induction by Golden Leaf Teaching School Hub",
      appropriate_body_period_id: appropriate_body_period.id,
      oauth_client: authorization.client
    )
  end
end
