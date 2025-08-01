RSpec.shared_examples "a sortable endpoint" do |additional_sorts = []|
  let!(:resources) do
    [
      create_resource(active_lead_provider:),
      create_resource(active_lead_provider:),
      create_resource(active_lead_provider:)
    ]
  end

  sorts = %i[created_at updated_at]
  sorts.union(additional_sorts).map { |sort| ["-", "+"].map { |direction| "#{direction}#{sort}" } }.flatten.each do |sort|
    it "returns the correct resources in the correct order" do
      # Sort resources based on the specified sort parameter.
      resources.sort_by!(&:"#{sort[1..]}").tap { |l| l.reverse! if sort[0] == "-" }

      authenticated_api_get(path, params: { sort: })

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eql("application/json; charset=utf-8")
      expect(response.body).to eq(serializer.render(resources, root: "data", **serializer_options))
    end
  end
end
