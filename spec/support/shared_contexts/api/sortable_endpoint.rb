RSpec.shared_examples "an API endpoint with sorting" do |additional_sorts = []|
  sorts = %w[created_at updated_at]
  sorts.union(additional_sorts).map { |sort| ["-", "+"].map { |direction| "#{direction}#{sort}" } }.flatten.each do |sort|
    it "calls the correct query" do
      expect(query).to receive(:new).with(a_hash_including(lead_provider_id: lead_provider.id, contract_period_id: contract_period.id, sort:)).and_call_original

      params = { sort: }
      params.deep_merge!(mandatory_params) if defined?(mandatory_params)

      authenticated_api_get(path, params:)
    end
  end
end
