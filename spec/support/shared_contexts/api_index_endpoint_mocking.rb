# frozen_string_literal: true

shared_examples "an API index endpoint (mocking)" do
  context "when authorized" do
    it "queries the data, paginates it and returns the serialized response" do
      query_results = response_type.none
      query_double = instance_double(query, query_method => query_results)
      allow(query).to receive(:new).and_return(query_double)

      # There's not an easy way of mocking pagy here. To avoid the `expect_any_instance_of` we would
      # need to switch to controller tests. Request specs don't want you to care about the internals
      # so aren't ideal for mocking.
      expect_any_instance_of(API::V3::PartnershipsController).to receive(:paginate).with(query_results).and_return(query_results) # rubocop:disable RSpec/StubbedMock, RSpec/AnyInstance

      serialized_response = { data: [{ id: "123" }] }
      allow(serializer).to receive(:render).with(query_results, root: "data").and_return(serialized_response.to_json)

      api_get(path)

      expect(response.status).to eq 200
      expect(parsed_response).to eq(serialized_response)
    end
  end

  context "when unauthorized" do
    it "returns 401 - unauthorized" do
      api_get(path, token: "incorrect-token")

      expect(response.status).to eq 401
    end
  end
end
