RSpec.describe ParityCheck::RequestBuilder do
  let(:lead_provider) { request.lead_provider }
  let(:path) { "/test-path" }
  let(:method) { :get }
  let(:options) { { foo: :bar } }
  let(:endpoint) { ParityCheck::Endpoint.new(method:, path:, options:) }
  let(:request) { FactoryBot.create(:parity_check_request, endpoint:) }
  let(:per_page) { described_class::PAGINATION_PER_PAGE }
  let(:instance) { described_class.new(request:) }

  it "has the correct attributes" do
    expect(instance).to have_attributes(request:)
  end

  describe "delegate methods" do
    it { is_expected.to delegate_method(:lead_provider).to(:request) }
    it { is_expected.to delegate_method(:endpoint).to(:request) }

    it { is_expected.to delegate_method(:method).to(:endpoint) }
    it { is_expected.to delegate_method(:path).to(:endpoint) }
    it { is_expected.to delegate_method(:options).to(:endpoint) }
  end

  describe "instance methods" do
    let(:tokens) { { lead_provider.ecf_id => "test_token" } }
    let(:ecf_url) { "https://ecf.example.com" }
    let(:rect_url) { "https://rect.example.com" }

    before do
      allow(Rails.application.config).to receive(:parity_check) do
        {
          enabled: true,
          tokens: tokens.to_json,
          ecf_url:,
          rect_url:,
        }
      end
    end

    describe "#url" do
      subject(:url) { instance.url(app:) }

      let(:app) { :ecf }

      it { is_expected.to eq("#{ecf_url}#{endpoint.path}") }

      context "when the path contains an ID but the options do not specify which one" do
        let(:path) { "/test-path/:id" }

        it { expect { url }.to raise_error(described_class::IDOptionMissingError, "Path contains ID, but options[:id] is missing") }
      end

      context "when the path contains an ID but the options[:id] method is missing" do
        let(:path) { "/test-path/:id" }
        let(:options) { { id: :unrecognized_id } }

        it { expect { url }.to raise_error(described_class::UnrecognizedPathIdError, "Method missing for path ID: unrecognized_id") }
      end

      context "when the path contains a statement_id" do
        let(:path) { "/test-path/:id" }
        let(:options) { { id: :statement_id } }
        let!(:statement) { FactoryBot.create(:statement, lead_provider:) }

        # Statement for different lead provider should not be used.
        before { FactoryBot.create(:statement) }

        it { is_expected.to eq("#{ecf_url}/test-path/#{statement.api_id}") }
      end
    end

    describe "#headers" do
      subject { instance.headers }

      it "returns the correct headers" do
        expect(instance.headers).to eq(
          "Authorization" => "Bearer test_token",
          "Accept" => "application/json",
          "Content-Type" => "application/json"
        )
      end
    end

    describe "#body" do
      subject(:body) { instance.body }

      context "when the body contains an example_statement_body" do
        let(:options) { { body: :example_statement_body } }

        it "returns the example statement body JSON encoded" do
          expect(body).to eq({
            data: {
              type: "statements",
              attributes: {
                content: "This is an example request body.",
              },
            },
          }.to_json)
        end
      end

      context "when the options do not specify a body" do
        let(:options) { {} }

        it { expect(body).to be_nil }
      end

      context "when the options[:body] method is missing" do
        let(:options) { { body: :unrecognized_body } }

        it { expect { body }.to raise_error(described_class::UnrecognizedRequestBodyError, "Method missing for body: unrecognized_body") }
      end
    end

    describe "#query" do
      subject(:query) { instance.query }

      context "when the query is a hash" do
        let(:options) { { query: { filter: { cohort: 2022 } } } }

        it { is_expected.to eq(options[:query]) }
      end

      context "when the query is not a hash" do
        let(:options) { { query: "filter=test" } }

        it { expect { query }.to raise_error(described_class::UnrecognizedQueryError, "Query must be a Hash: filter=test") }
      end

      context "when pagination is enabled" do
        let(:options) { { paginate: true } }

        it { is_expected.to eq({ page: { page: 1, per_page: } }) }
      end

      context "when pagination is enabled and there are query parameters" do
        let(:options) { { paginate: true, query: { filter: { cohort: 2022 } } } }

        it { is_expected.to eq({ filter: { cohort: 2022 }, page: { page: 1, per_page: } }) }
      end
    end

    describe "#page" do
      subject { instance.page }

      context "when pagination is enabled" do
        let(:options) { { paginate: true } }

        it { is_expected.to eq(1) }
      end

      context "when pagination is not enabled" do
        let(:options) { { paginate: false } }

        it { is_expected.to be_nil }
      end
    end

    describe "#advance_page" do
      subject(:advance_page) { instance.advance_page(previous_response) }

      let(:previous_response) { FactoryBot.build(:parity_check_response) }
      let(:partial_page_of_data) { { data: Array.new(per_page / 2, { key: :value }) }.to_json }
      let(:full_page_of_data) { { data: Array.new(per_page, { key: :value }) }.to_json }

      context "when pagination is enabled" do
        let(:options) { { paginate: true } }

        context "when there is another page (both APIs return full sets of data)" do
          let(:previous_response) { FactoryBot.build(:parity_check_response, ecf_body: full_page_of_data, rect_body: full_page_of_data) }

          it "returns true and increments the page number" do
            expect(advance_page).to be_truthy
            expect(instance.page).to eq(2)
          end
        end

        context "when there is another page (only one API returns a full set of data)" do
          let(:previous_response) { FactoryBot.build(:parity_check_response, ecf_body: partial_page_of_data, rect_body: full_page_of_data) }

          it "returns true and increments the page number" do
            expect(advance_page).to be_truthy
            expect(instance.page).to eq(2)
          end
        end

        context "when there are no more pages" do
          let(:previous_response) { FactoryBot.build(:parity_check_response, ecf_body: partial_page_of_data, rect_body: partial_page_of_data) }

          it "returns false and does not increment the page number" do
            expect(advance_page).to be_falsy
            expect(instance.page).to eq(1)
          end
        end
      end

      context "when pagination is disabled" do
        let(:options) { { paginate: false } }

        it { is_expected.to be_falsy }
        it { expect(instance.page).to be_nil }
      end
    end
  end
end
