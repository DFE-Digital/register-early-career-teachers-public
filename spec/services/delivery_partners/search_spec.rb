describe DeliveryPartners::Search do
  describe 'dealing with search terms' do
    subject { described_class.new(query_string) }

    let(:query_string) { nil }

    describe "#search" do
      context 'when the search string is blank' do
        let(:query_string) { ' ' }

        it 'applies no conditions and returns all delivery partners' do
          subject.search

          expect(subject.search.to_sql).to start_with(%(SELECT "delivery_partners".* FROM "delivery_partners" ORDER BY))
        end
      end

      context 'when the search string contains some text' do
        let(:query_string) { 'Captain Scrummy' }

        it 'initiates a full text search with the given search string' do
          expect(subject.search.to_sql).to include(%{WHERE (name ILIKE '%Captain Scrummy%')})
        end
      end

      context 'ordering' do
        before { allow(DeliveryPartner).to receive(:where).and_call_original }

        it 'defaults to order by name ascending' do
          expect(subject.search.to_sql).to include(%(ORDER BY "delivery_partners"."name" ASC))
        end
      end
    end
  end
end
