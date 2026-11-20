RSpec.describe API::Induction::ErrorHandleable, type: :request do
  let(:authorization) { FactoryBot.create(:api_oauth_authorization, :with_token) }

  def api_response_when(error)
    concern = described_class
    controller = Class.new(ActionController::API) do
      include concern

      define_method(:show) { raise error }
    end

    with_routing do |set|
      set.draw { get "/error", to: controller.action(:show) }
      get "/error"
      response
    end
  end

  APIRoute.with_concern(described_class, only: %i[induction]).each do |route|
    it "rejects a request without a body on #{route}" do
      process(route.verb, route.path, headers: bearer_auth_headers(authorization:), as: :json)

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body).to eq("errors" => [{ "title" => "Bad request", "detail" => "Correct json data structure required. See API docs for reference." }])
    end
  end

  it "renders induction errors with their HTTP status" do
    {
      TeacherNotFound: [:not_found, "Resource not found"],
      AlreadyClaimed: [:conflict, "Conflict"],
      NotEligible: [:unprocessable_content, "Unprocessable content"],
      TRSUnavailable: [:service_unavailable, "Service unavailable"],
    }.each do |error, (status, title)|
      api_response = api_response_when(API::AppropriateBodies::Induction.const_get(error).new("Bang"))

      expect(api_response).to have_http_status(status)
      expect(api_response.parsed_body).to eq("errors" => [{ "title" => title, "detail" => "Bang" }])
    end
  end

  it "renders each invalid field as its own error" do
    errors = ActiveModel::Errors.new(PendingInductionSubmission.new)
    errors.add(:date_of_birth, "Enter a date of birth")
    errors.add(:training_programme, "Choose an induction training programme")

    api_response = api_response_when(API::AppropriateBodies::Induction::Invalid.new(errors))

    expect(api_response).to have_http_status(:unprocessable_content)
    expect(api_response.parsed_body).to eq("errors" => [
      { "title" => "date_of_birth", "detail" => "Enter a date of birth" },
      { "title" => "training_programme", "detail" => "Choose an induction training programme" },
    ])
  end
end
