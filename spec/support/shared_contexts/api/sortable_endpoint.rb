RSpec.shared_examples "a sortable endpoint" do |additional_sorts = []|
  let!(:resources) do
    [
      travel_to(2.days.ago) { create_resource(active_lead_provider:) }.tap { it.update!(updated_at: 1.day.ago, api_updated_at: 2.hours.ago) },
      create_resource(active_lead_provider:).tap { it.update!(updated_at: 1.minute.ago, api_updated_at: 3.hours.ago) },
      travel_to(5.days.ago) { create_resource(active_lead_provider:) }.tap { it.update!(updated_at: 5.days.ago, api_updated_at: 1.day.ago) },
    ]
  end

  def transform_sort_attribute(sort_attribute)
    return "api_updated_at" if sort_attribute == "updated_at"

    sort_attribute
  end

  sorts = %i[created_at updated_at]
  sorts.union(additional_sorts).map { |sort| ["-", "+"].map { |direction| "#{direction}#{sort}" } }.flatten.each do |sort|
    it "returns the correct resources in the correct order" do
      # Sort resources based on the specified sort parameter.
      sort_attribute = transform_sort_attribute(sort[1..])
      resources.sort_by!(&:"#{sort_attribute}").tap { |l| l.reverse! if sort[0] == "-" }

      authenticated_api_get(path, params: { sort: })

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eql("application/json; charset=utf-8")
      expect(response.body).to eq(serializer.render(resources, root: "data", **serializer_options))
    end
  end
end
