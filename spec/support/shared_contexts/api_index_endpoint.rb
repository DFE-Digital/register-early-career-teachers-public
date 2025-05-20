# frozen_string_literal: true

shared_examples "an API index endpoint" do
  context "when authorized" do
    context "when 2 resources exist for current_lead_provider" do
      let!(:resources) do
        [
          create_resource(lead_provider: current_lead_provider),
          create_resource(lead_provider: current_lead_provider)
        ]
      end

      before do
        # Another resource for a different lead provider.
        create_resource(lead_provider: create(:lead_provider))
      end

      it "returns the correct resources in the serialized format" do
        api_get(path)

        expect(response.status).to eq 200
        expect(response.content_type).to eql("application/json")
        expect(response.body).to eq(serializer.render(resources, root: "data"))
      end
    end
  end

  context "when unauthorized" do
    it "returns 401 - unauthorized" do
      api_get(path, token: "incorrect-token")

      expect(response.status).to eq 401
    end
  end
end

shared_examples "an API index endpoint with pagination" do
  context "with pagination" do
    before do
      8.times { create_resource(lead_provider: current_lead_provider) }
    end

    it "returns 5 resources on page 1" do
      api_get(path, params: { page: { per_page: 5, page: 1 } })

      expect(response.status).to eq 200
      expect(parsed_response[:data].size).to eq(5)
    end

    it "returns 3 resources on page 2" do
      api_get(path, params: { page: { per_page: 5, page: 2 } })

      expect(response.status).to eq 200
      expect(parsed_response[:data].size).to eq(3)
    end

    it "returns bad request for pages beyond total pages" do
      api_get(path, params: { page: { per_page: 5, page: 3 } })

      expect(response.status).to eq 400
    end

    it "returns bad request when requesting page -1" do
      api_get(path, params: { page: { per_page: 5, page: -1 } })

      expect(response.status).to eq 400
    end
  end
end
