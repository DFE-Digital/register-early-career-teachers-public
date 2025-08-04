RSpec.shared_examples "a filter validatable endpoint" do |required_filters = []|
  required_filters.each do |filter|
    it "validates the presence of the '#{filter}' filter" do
      authenticated_api_get(path[/[^?]+/], params: { filter: {} })

      expect(response).to have_http_status(:bad_request)
      expect(response.content_type).to eql("application/json; charset=utf-8")
      expect(response.body).to include("The filter '#/#{filter}' must be included in your request")
    end

    it "validates that the filter is a hash" do
      authenticated_api_get(path[/[^?]+/], params: { filter: "not-a-hash" })

      expect(response).to have_http_status(:bad_request)
      expect(response.content_type).to eql("application/json; charset=utf-8")
      expect(response.body).to include("Filter must be a hash")
    end
  end
end
