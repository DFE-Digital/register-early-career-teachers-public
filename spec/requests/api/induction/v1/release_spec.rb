RSpec.describe "POST /api/induction/v1/teachers/:trn/release", type: :request do
  let(:appropriate_body_period) { FactoryBot.create(:appropriate_body_period, name: "Golden Leaf Teaching School Hub") }
  let(:authorization) { FactoryBot.create(:api_oauth_authorization, :with_token, appropriate_body_period:) }
  let(:teacher) { FactoryBot.create(:teacher, :with_name) }
  let!(:induction_period) { FactoryBot.create(:induction_period, :unfinished, teacher:, appropriate_body_period:) }
  let(:trn) { teacher.trn }
  let(:released_on) { 1.day.ago.to_date }
  let(:params) { { released_on: released_on.iso8601, number_of_terms: 3 } }

  def release(params: self.params, headers: bearer_auth_headers(authorization:))
    post("/api/induction/v1/teachers/#{trn}/release", params:, headers:, as: :json)
  end

  it "releases the ECT" do
    release

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq(
      "trn" => trn,
      "full_name" => "John Keating",
      "released_on" => released_on.iso8601,
      "number_of_terms" => 3.0
    )
    expect(induction_period.reload).to have_attributes(finished_on: released_on, number_of_terms: 3, outcome: nil)
    expect(Event.where(event_type: "induction_period_closed").sole).to have_attributes(
      author_type: "appropriate_body_api",
      author_name: "Golden Leaf Teaching School Hub",
      heading: "John Keating was released by Golden Leaf Teaching School Hub",
      appropriate_body_period_id: appropriate_body_period.id,
      oauth_client: authorization.client
    )
  end
end
