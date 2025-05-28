shared_examples "an error rescuable endpoint" do
  describe "handling `UnpermittedParameters` exceptions", skip: "endpoint not ready" do
    before do
      send("authenticated_api_#{request_method}", path, params: { foo: "bar" })
    end

    it "renders correct error message" do
      expect(parsed_response_errors).to eq([
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

  describe "handling `BadRequest` exceptions", skip: "endpoint not ready" do
    before do
      authenticated_api_get(path, params: { filter: { updated_since: "invalid-date" } })
    end

    it "renders correct error message" do
      expect(parsed_response_errors).to eq([
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

  describe "handling `ArgumentError` exceptions", skip: "endpoint not ready" do
    before do
      authenticated_api_get(path)
    end

    it "renders correct error message" do
      expect(parsed_response_errors).to eq([
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

  describe "handling `FilterValidationError` exceptions", skip: "endpoint not ready" do
    before do
      authenticated_api_get(path, params: { filter: { state: "foo" } })
    end

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
