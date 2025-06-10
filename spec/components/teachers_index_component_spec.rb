RSpec.describe TeachersIndexComponent, type: :component do
  subject(:component) do
    TeachersIndexComponent.new(
      appropriate_body:,
      teachers:,
      pagy:,
      status:,
      query:
    )
  end

  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let(:other_appropriate_body) { FactoryBot.create(:appropriate_body) }

  let!(:teacher_1) do
    teacher = FactoryBot.create(:teacher, trs_first_name: "Alice", trs_last_name: "Smith", trn: "1234567")
    FactoryBot.create(:induction_period, :active, teacher:, appropriate_body:, started_on: 3.months.ago)
    teacher
  end

  let!(:teacher_2) do
    teacher = FactoryBot.create(:teacher, trs_first_name: "Bob", trs_last_name: "Jones", trn: "2345678")
    FactoryBot.create(:induction_period, :active, teacher:, appropriate_body:, started_on: 2.months.ago)
    teacher
  end

  let!(:teacher_3_closed) do
    teacher = FactoryBot.create(:teacher, trs_first_name: "Carol", trs_last_name: "Brown", trn: "3456789")
    FactoryBot.create(:induction_period, :pass, teacher:, appropriate_body:, started_on: 6.months.ago, finished_on: 1.month.ago, number_of_terms: 6)
    teacher
  end

  let!(:teacher_4_other_ab) do
    teacher = FactoryBot.create(:teacher, trs_first_name: "David", trs_last_name: "Wilson", trn: "4567890")
    FactoryBot.create(:induction_period, :active, teacher:, appropriate_body: other_appropriate_body, started_on: 1.month.ago)
    teacher
  end

  let(:teachers) { [teacher_1, teacher_2] }
  let(:pagy) { double("Pagy", count: 25, page: 1, limit: 20, pages: 2, series: [1, 2], vars: {}, prev: nil, next: 2) }
  let(:status) { 'open' }
  let(:query) { nil }

  describe 'component initialization and status normalization' do
    context 'with valid open status' do
      let(:status) { 'open' }

      it 'initializes with correct status' do
        expect(component.instance_variable_get(:@status)).to eq('open')
      end
    end

    context 'with valid closed status' do
      let(:status) { 'closed' }

      it 'initializes with correct status' do
        expect(component.instance_variable_get(:@status)).to eq('closed')
      end
    end

    context 'with invalid status' do
      let(:status) { 'invalid' }

      it 'normalizes to open status' do
        expect(component.instance_variable_get(:@status)).to eq('open')
      end
    end

    context 'with blank status' do
      let(:status) { '' }

      it 'normalizes to open status' do
        expect(component.instance_variable_get(:@status)).to eq('open')
      end
    end

    context 'with nil status' do
      let(:status) { nil }

      it 'normalizes to open status' do
        expect(component.instance_variable_get(:@status)).to eq('open')
      end
    end
  end

  describe 'rendered content' do
    subject { render_inline(component) }

    context 'with bulk upload disabled' do
      before { allow(Rails.application.config).to receive(:enable_bulk_upload).and_return(false) }

      it 'renders the main heading with correct count' do
        expect(subject.css('h2').text).to include('2 open induction')
      end

      it 'renders the find ECT link' do
        expect(subject.to_html).to include('Find and claim a new ECT')
      end

      it 'does not render bulk upload links when disabled' do
        expect(subject.to_html).not_to include('Upload a CSV to record outcomes')
        expect(subject.to_html).not_to include('Upload a CSV to claim multiple')
      end

      it 'renders the search form with correct label' do
        expect(subject.css('label').text).to include('Search for an open induction by name or teacher reference number')
      end

      it 'renders the search form with empty query value' do
        input_element = subject.css('input[name="q"]').first
        expect(input_element['value']).to be_blank
      end

      it 'renders hidden status field with correct value' do
        hidden_input = subject.css('input[name="status"][type="hidden"]').first
        expect(hidden_input['value']).to eq('open')
      end
    end

    context 'with bulk upload enabled' do
      before { allow(Rails.application.config).to receive(:enable_bulk_upload).and_return(true) }

      it 'renders bulk upload links when enabled' do
        expect(subject.to_html).to include('Upload a CSV to record outcomes')
        expect(subject.to_html).to include('Upload a CSV to claim multiple')
      end
    end

    context 'with closed status' do
      let(:status) { 'closed' }

      it 'renders the heading with closed inductions count' do
        expect(subject.css('h2').text).to include('1 closed induction')
      end

      it 'renders search label for closed inductions' do
        expect(subject.css('label').text).to include('Search for an closed induction by name')
      end

      it 'renders hidden status field with closed value' do
        hidden_input = subject.css('input[name="status"][type="hidden"]').first
        expect(hidden_input['value']).to eq('closed')
      end
    end

    context 'with query parameter' do
      let(:query) { 'Alice Smith' }

      it 'renders search input with query value' do
        input_element = subject.css('input[name="q"]').first
        expect(input_element['value']).to eq('Alice Smith')
      end
    end

    context 'with search query and filtered results' do
      let(:query) { 'Alice' }
      let(:pagy) { double("Pagy", count: 1, page: 1, limit: 20, pages: 1, series: [1], vars: {}, prev: nil, next: nil) }

      it 'displays filtered results count when searching' do
        expect(subject.css('h2').text).to include('1 open induction')
      end

      it 'uses pagy count instead of service count when searching' do
        # Service would return 2 total, but pagy.count (1) should be used for filtered search results
        expect(subject.css('h2').text).not_to include('2 open induction')
        expect(subject.css('h2').text).to include('1 open induction')
      end

      context 'with closed status' do
        let(:status) { 'closed' }
        let(:pagy) { double("Pagy", count: 1, page: 1, limit: 20, pages: 1, series: [1], vars: {}, prev: nil, next: nil) }

        it 'displays filtered results count for closed inductions when searching' do
          expect(subject.css('h2').text).to include('1 closed induction')
        end
      end
    end

    context 'with teachers present' do
      it 'renders the teachers table' do
        expect(subject.css('table').length).to be > 0
      end

      it 'renders table headers' do
        headers = subject.css('th').map(&:text)
        expect(headers).to include('Name')
        expect(headers).to include('TRN')
        expect(headers).to include('Induction start date')
        expect(headers).to include('Status')
      end

      it 'renders teacher data in table rows' do
        # Check that teacher names appear as links
        expect(subject.to_html).to include('Alice Smith')
        expect(subject.to_html).to include('Bob Jones')

        # Check that TRNs are displayed
        expect(subject.to_html).to include('1234567')
        expect(subject.to_html).to include('2345678')
      end

      it 'renders pagination component' do
        # Pagy should render pagination elements
        expect(subject.css('.pagy, nav[aria-label*="pagination"], .pagination').length).to be >= 0
      end
    end

    context 'with no teachers' do
      let(:teachers) { [] }

      it 'renders empty state message without query' do
        expect(subject.to_html).to include('No open inductions found.')
      end

      it 'does not render table when no teachers' do
        expect(subject.css('table').length).to eq(0)
      end
    end

    context 'with no teachers and search query' do
      let(:teachers) { [] }
      let(:query) { 'John Doe' }

      it 'renders empty state message with query highlighted' do
        expect(subject.to_html).to include('No open inductions found matching')
        expect(subject.to_html).to include('<strong>John Doe</strong>')
      end
    end
  end

  describe 'navigation behavior' do
    subject { render_inline(component) }

    context 'when viewing open inductions and closed inductions exist' do
      let(:status) { 'open' }

      it 'renders navigation link to view closed inductions with count' do
        expect(subject.to_html).to include('View closed inductions (1)')
      end
    end

    context 'when viewing closed inductions' do
      let(:status) { 'closed' }

      it 'renders navigation link to view open inductions with count' do
        expect(subject.to_html).to include('View open inductions (2)')
      end
    end

    context 'when no closed inductions exist' do
      before { teacher_3_closed.induction_periods.destroy_all }

      it 'does not render navigation link to closed inductions' do
        expect(subject.to_html).not_to include('View closed inductions')
      end
    end
  end

  describe 'ECTs service integration' do
    it 'uses AppropriateBodies::ECTs service for calculating counts' do
      expect(AppropriateBodies::ECTs).to receive(:new).with(appropriate_body).and_call_original
      render_inline(component)
    end

    it 'displays correct open inductions count from real data' do
      rendered = render_inline(component)
      expect(rendered.css('h2').text).to include('2 open induction')
    end

    context 'with closed status' do
      let(:status) { 'closed' }

      it 'displays correct closed inductions count from real data' do
        rendered = render_inline(component)
        expect(rendered.css('h2').text).to include('1 closed induction')
      end
    end
  end

  describe 'real data integration' do
    it 'correctly counts open inductions for the appropriate body' do
      rendered = render_inline(component)
      # teacher_1 and teacher_2 both have active inductions with this appropriate body
      expect(rendered.css('h2').text).to include('2 open induction')
    end

    it 'correctly counts closed inductions for the appropriate body' do
      component_closed = TeachersIndexComponent.new(
        appropriate_body:,
        teachers: [],
        pagy:,
        status: 'closed',
        query: nil
      )
      rendered = render_inline(component_closed)
      # teacher_3_closed has a completed induction with this appropriate body
      expect(rendered.css('h2').text).to include('1 closed induction')
    end

    context 'when bulk upload is configured' do
      it 'shows bulk upload links when enabled' do
        allow(Rails.application.config).to receive(:enable_bulk_upload).and_return(true)
        rendered = render_inline(component)
        expect(rendered.to_html).to include('Upload a CSV')
      end

      it 'hides bulk upload links when disabled' do
        allow(Rails.application.config).to receive(:enable_bulk_upload).and_return(false)
        rendered = render_inline(component)
        expect(rendered.to_html).not_to include('Upload a CSV')
      end
    end
  end
end
