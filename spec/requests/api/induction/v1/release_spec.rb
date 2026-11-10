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

  it "rejects a missing or unknown token" do
    release(headers: {})
    expect(response).to have_http_status(:unauthorized)

    release(headers: bearer_auth_headers(authorization:, token: "unknown"))
    expect(response).to have_http_status(:unauthorized)
  end

  it "rejects a request without a body" do
    post("/api/induction/v1/teachers/#{trn}/release", headers: bearer_auth_headers(authorization:), as: :json)

    expect(response).to have_http_status(:bad_request)
    expect(response.parsed_body).to eq("errors" => [{ "title" => "Bad request", "detail" => "Correct json data structure required. See API docs for reference." }])
  end

  context "when no teacher has the TRN" do
    let(:trn) { "0000000" }

    it "is not found" do
      release

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body).to eq("errors" => [{ "title" => "Resource not found", "detail" => "Nothing could be found for the provided details" }])
    end
  end

  context "when the teacher's ongoing induction is with another appropriate body" do
    let!(:induction_period) { FactoryBot.create(:induction_period, :unfinished, teacher:) }

    it "is not found" do
      release

      expect(response).to have_http_status(:not_found)
      expect(induction_period.reload.finished_on).to be_nil
    end
  end

  context "when the teacher has already been released" do
    let!(:induction_period) { FactoryBot.create(:induction_period, teacher:, appropriate_body_period:) }

    it "is not found" do
      release

      expect(response).to have_http_status(:not_found)
    end
  end

  context "when the number of terms is missing" do
    let(:params) { super().except(:number_of_terms) }

    it "is unprocessable" do
      release

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body).to eq("errors" => [{ "title" => "number_of_terms", "detail" => "Enter a number of terms" }])
      expect(induction_period.reload.finished_on).to be_nil
    end
  end

  context "when the finish date is in the future" do
    let(:released_on) { 1.day.from_now.to_date }

    it "is unprocessable" do
      release

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body).to eq("errors" => [{ "title" => "finished_on", "detail" => "End date cannot be in the future" }])
      expect(induction_period.reload.finished_on).to be_nil
    end
  end
end
