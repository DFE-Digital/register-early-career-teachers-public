RSpec.describe API::BaseController, type: :controller do
  describe "handling `UnpermittedParameters` exceptions" do
    controller do
      def index
        raise ActionController::UnpermittedParameters.new(params: { foo: "bar" })
      end
    end

    before do
      request.headers["HTTP_AUTHORIZATION"] = "Bearer #{token}"
      get :index
    end

    let(:token) { FactoryBot.create(:api_token).token }
    let(:parsed_response) { JSON.parse(response.body) }

    it "renders correct error message" do
      expect(parsed_response["errors"]).to eq([
        {
          "detail" => ["params", { "foo" => "bar" }],
          "title" => "Unpermitted parameters",
        },
      ])
    end

    it "returns 422" do
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "handling `BadRequest` exceptions" do
    controller do
      def index
        raise ActionController::BadRequest, "testing"
      end
    end

    before do
      request.headers["HTTP_AUTHORIZATION"] = "Bearer #{token}"
      get :index
    end

    let(:token) { FactoryBot.create(:api_token).token }
    let(:parsed_response) { JSON.parse(response.body) }

    it "renders correct error message" do
      expect(parsed_response["errors"]).to eq([
        {
          "detail" => "testing",
          "title" => "Bad request",
        },
      ])
    end

    it "returns 400" do
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "handling `ArgumentError` exceptions" do
    controller do
      def index
        raise ArgumentError, "testing"
      end
    end

    before do
      request.headers["HTTP_AUTHORIZATION"] = "Bearer #{token}"
      get :index
    end

    let(:token) { FactoryBot.create(:api_token).token }
    let(:parsed_response) { JSON.parse(response.body) }

    it "renders correct error message" do
      expect(parsed_response["errors"]).to eq([
        {
          "detail" => "testing",
          "title" => "Bad request",
        },
      ])
    end

    it "returns 400" do
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "handling `FilterValidationError` exceptions" do
    controller do
      def index
        raise API::Errors::FilterValidationError, "testing"
      end
    end

    before do
      request.headers["HTTP_AUTHORIZATION"] = "Bearer #{token}"
      get :index
    end

    let(:token) { FactoryBot.create(:api_token).token }
    let(:parsed_response) { JSON.parse(response.body) }

    it "renders correct error message" do
      expect(parsed_response["errors"]).to eq([
        {
          "detail" => "testing",
          "title" => "Unpermitted parameters",
        },
      ])
    end

    it "returns 422" do
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
