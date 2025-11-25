RSpec.shared_examples "a sortable endpoint" do |additional_sorts = [], updated_at_column: :api_updated_at|
  let!(:resources) do
    [
      travel_to(2.days.ago) { create_resource(active_lead_provider:) }.tap { it.update!("#{updated_at_column}": 2.hours.ago) },
      create_resource(active_lead_provider:).tap { it.update!("#{updated_at_column}": 3.hours.ago) },
      travel_to(5.days.ago) { create_resource(active_lead_provider:) }.tap { it.update!("#{updated_at_column}": 1.day.ago) },
    ]
  end
  let(:updated_at_sort_attribute) { updated_at_column.to_s }

  def transform_sort_attribute(sort_attribute)
    if sort_attribute == "updated_at"
      updated_at_sort_attribute
    else
      sort_attribute
    end
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
      expect(response.body).to eq(serializer.render(resources.map(&:reload), root: "data", **serializer_options))
    end
  end
end
