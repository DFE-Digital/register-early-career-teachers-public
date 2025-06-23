RSpec.describe EmptyStateMessage, type: :concern do
  let(:test_class) do
    Class.new do
      include EmptyStateMessage
      include ActionView::Helpers::TagHelper

      attr_reader :status, :query

      def initialize(status:, query:)
        @status = status
        @query = query
      end
    end
  end

  let(:instance) { test_class.new(status:, query:) }

  describe '#empty_state_message' do
    context 'without query' do
      let(:query) { nil }

      context 'with open status' do
        let(:status) { 'open' }

        it 'returns correct message' do
          expect(instance.send(:empty_state_message)).to eq('No open inductions found.')
        end
      end

      context 'with closed status' do
        let(:status) { 'closed' }

        it 'returns correct message' do
          expect(instance.send(:empty_state_message)).to eq('No closed inductions found.')
        end
      end
    end

    context 'with query' do
      let(:query) { 'Alice Smith' }
      let(:status) { 'open' }

      it 'returns message with highlighted query using tag helper' do
        expected_message = 'No open inductions found matching "<strong class="govuk-!-font-weight-bold">Alice Smith</strong>".'
        expect(instance.send(:empty_state_message)).to eq(expected_message)
      end

      it 'properly escapes special characters' do
        instance = test_class.new(status: 'open', query: "O'Connor & <test>")
        message = instance.send(:empty_state_message)
        expect(message).to include('<strong class="govuk-!-font-weight-bold">O&#39;Connor &amp; &lt;test&gt;</strong>')
      end
    end

    context 'with blank query' do
      let(:query) { '' }
      let(:status) { 'open' }

      it 'treats blank query as no query' do
        expect(instance.send(:empty_state_message)).to eq('No open inductions found.')
      end
    end
  end

  describe '#highlighted_query' do
    let(:status) { 'open' }
    let(:query) { 'John Doe' }

    it 'returns query wrapped in strong tag with GOV.UK class' do
      expected_html = '<strong class="govuk-!-font-weight-bold">John Doe</strong>'
      expect(instance.send(:highlighted_query)).to eq(expected_html)
    end

    it 'escapes special characters' do
      instance = test_class.new(status: 'open', query: '<script>alert("xss")</script>')
      highlighted = instance.send(:highlighted_query)
      expect(highlighted).to include('&lt;script&gt;')
      expect(highlighted).not_to include('<script>')
    end
  end

  describe '#message_with_query' do
    let(:status) { 'open' }
    let(:query) { 'Test Query' }
    let(:base_message) { 'No open inductions found' }

    it 'returns message with highlighted query' do
      result = instance.send(:message_with_query, base_message)
      expect(result).to include(base_message)
      expect(result).to include('matching')
      expect(result).to include('<strong class="govuk-!-font-weight-bold">Test Query</strong>')
      expect(result).to be_html_safe
    end
  end
end
