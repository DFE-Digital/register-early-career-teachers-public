RSpec.describe "POST /api/induction/v1/teachers/:trn/claim", type: :request do
  include_context "test TRS API returns a teacher"

  let(:appropriate_body_period) { FactoryBot.create(:appropriate_body_period, name: "Golden Leaf Teaching School Hub") }
  let(:authorization) { FactoryBot.create(:api_oauth_authorization, :with_token, appropriate_body_period:) }
  let(:trn) { "1234567" }
  let(:claimed_from) { 1.month.ago.to_date }
  let(:params) { { date_of_birth: "2001-05-13", claimed_from: claimed_from.iso8601, training_programme: "school_led" } }

  def claim(params: self.params, headers: bearer_auth_headers(authorization:))
    post("/api/induction/v1/teachers/#{trn}/claim", params:, headers:, as: :json)
  end

  it "claims the ECT for the appropriate body" do
    claim

    expect(response).to have_http_status(:created)
    expect(response.parsed_body).to eq(
      "trn" => trn,
      "full_name" => "Kirk Van Houten",
      "claimed_from" => claimed_from.iso8601,
      "training_programme" => "school_led"
    )
    expect(Teacher.find_by!(trn:).ongoing_induction_period.appropriate_body_period).to eq(appropriate_body_period)
    expect(Event.where(event_type: "induction_period_opened").sole).to have_attributes(
      author_type: "appropriate_body_api",
      author_name: "Golden Leaf Teaching School Hub",
      appropriate_body_period_id: appropriate_body_period.id,
      oauth_client: authorization.client
    )
  end
end
