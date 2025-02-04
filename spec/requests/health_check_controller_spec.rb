RSpec.describe "Health check" do
  describe "GET /healthcheck" do
    it 'returns some JSON describing the application health' do
      get "/healthcheck"

      expect(JSON.parse(response.body)).to eql(
        {
          'commit_sha' => 'UNKNOWN',
          'database' => 'connected',
        }
      )
    end

    context 'when the commit SHA is known' do
      before do
        allow(ENV).to receive(:fetch).with('COMMIT_SHA', 'UNKNOWN').and_return('abc123def')
      end

      it 'returns the commit sha' do
        get "/healthcheck"

        expect(JSON.parse(response.body).fetch('commit_sha')).to eql('abc123def')
      end
    end

    context 'when the database is not connected' do
      before do
        allow(ActiveRecord::Base.connection).to receive(:execute).and_raise(PG::ConnectionBad)
      end

      it 'returns not connected' do
        get "/healthcheck"

        expect(JSON.parse(response.body).fetch('database')).to eql('not connected')
      end
    end
  end
end
