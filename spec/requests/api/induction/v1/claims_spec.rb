RSpec.describe "POST /api/induction/v1/teachers/:trn/claim", type: :request do
  include_context "test TRS API returns a teacher"

  let(:appropriate_body_period) { FactoryBot.create(:appropriate_body_period, name: "Golden Leaf Teaching School Hub") }
  let(:authorization) { FactoryBot.create(:api_oauth_authorization, :with_token, appropriate_body_period:) }
  let(:trn) { "1234567" }
  let(:started_on) { 1.month.ago.to_date }
  let(:params) { { date_of_birth: "2001-05-13", started_on: started_on.iso8601, training_programme: "school_led" } }

  def claim(params: self.params, headers: bearer_auth_headers(authorization:))
    post("/api/induction/v1/teachers/#{trn}/claim", params:, headers:, as: :json)
  end

  it "claims the ECT for the appropriate body" do
    claim

    expect(response).to have_http_status(:created)
    expect(response.parsed_body).to eq(
      "trn" => trn,
      "full_name" => "Kirk Van Houten",
      "started_on" => started_on.iso8601,
      "training_programme" => "school_led"
    )
    expect(Teacher.find_by!(trn:).ongoing_induction_period.appropriate_body_period).to eq(appropriate_body_period)
    expect(Event.where(event_type: "induction_period_opened").sole).to have_attributes(
      author_type: "oauth_client",
      author_name: authorization.client.name,
      appropriate_body_period_id: appropriate_body_period.id
    )
  end

  it "rejects a missing or unknown token" do
    claim(headers: {})
    expect(response).to have_http_status(:unauthorized)

    claim(headers: bearer_auth_headers(authorization:, token: "unknown"))
    expect(response).to have_http_status(:unauthorized)
  end

  context "when TRS cannot find the teacher" do
    include_context "test TRS API returns nothing"

    it "is not found" do
      claim

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body).to eq("errors" => [{ "title" => "Resource not found", "detail" => "Nothing could be found for the provided details" }])
    end
  end

  context "when TRS is unavailable" do
    include_context "test TRS API is unavailable"

    it "is unavailable" do
      claim

      expect(response).to have_http_status(:service_unavailable)
      expect(response.parsed_body).to eq("errors" => [{ "title" => "Service unavailable", "detail" => "The Teaching Record System is unavailable. Try again later." }])
    end
  end

  context "when TRS times out" do
    include_context "test TRS API times out"

    it "is unavailable" do
      claim

      expect(response).to have_http_status(:service_unavailable)
      expect(response.parsed_body).to eq("errors" => [{ "title" => "Service unavailable", "detail" => "The Teaching Record System is unavailable. Try again later." }])
    end
  end

  context "when the teacher is prohibited from teaching" do
    include_context "test TRS API returns a teacher prohibited from teaching"

    it "is unprocessable" do
      claim

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body).to eq("errors" => [{ "title" => "Unprocessable content", "detail" => "The teacher is prohibited from teaching" }])
    end
  end

  it "rejects a request without a body" do
    post("/api/induction/v1/teachers/#{trn}/claim", headers: bearer_auth_headers(authorization:), as: :json)

    expect(response).to have_http_status(:bad_request)
    expect(response.parsed_body).to eq("errors" => [{ "title" => "Bad request", "detail" => "Correct json data structure required. See API docs for reference." }])
  end

  it "only reports errors on the fields the caller sends" do
    training_programme_error = { "errors" => [{ "title" => "training_programme", "detail" => "Choose an induction training programme" }] }

    claim(params: params.merge(training_programme: "bogus"))
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body).to eq(training_programme_error)

    claim(params: params.except(:training_programme))
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body).to eq(training_programme_error)
  end

  context "when the claim is invalid" do
    let(:params) { super().merge(date_of_birth: nil) }

    it "is unprocessable" do
      claim

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to include({ "title" => "date_of_birth", "detail" => "Enter a date of birth" })
    end
  end

  context "when the teacher has an ongoing induction period" do
    let(:teacher) { FactoryBot.create(:teacher, trn:) }

    it "conflicts when it is with this appropriate body" do
      FactoryBot.create(:induction_period, :unfinished, teacher:, appropriate_body_period:)

      claim

      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body).to eq("errors" => [{ "title" => "Conflict", "detail" => "The teacher already has an ongoing induction period with this appropriate body" }])
    end

    it "conflicts when it is with another appropriate body" do
      FactoryBot.create(:induction_period, :unfinished, teacher:)

      claim

      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body).to eq("errors" => [{ "title" => "Conflict", "detail" => "The teacher has an ongoing induction period with another appropriate body" }])
    end
  end
end
