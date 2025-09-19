# The base queries should remain optimal; any use-case specific includes should
# be made on the returned scope or specific subclasses.
RSpec.shared_examples "a query that avoids includes" do
  let(:params) { {} }

  it "does not preload any associations" do
    query = described_class.new(**params)

    result = query.scope.first

    result.class.reflect_on_all_associations.each do |association|
      expect(result.association(association.name)).not_to be_loaded
    end
  end
end
