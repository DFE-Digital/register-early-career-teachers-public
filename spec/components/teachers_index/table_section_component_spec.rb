RSpec.describe TeachersIndex::TableSectionComponent, type: :component do
  subject(:rendered) { render_inline(component) }

  let(:component) do
    TeachersIndex::TableSectionComponent.new(
      teachers:,
      pagy:,
      status:,
      query:
    )
  end

  let(:pagy) { double("Pagy", count: 25, page: 1, limit: 20, pages: 2, series: [1, 2], vars: {}, prev: nil, next: 2) }
  let(:status) { 'open' }
  let(:query) { nil }

  context 'with teachers present' do
    around do |example|
      travel_to(Date.new(2024, 6, 15)) do
        example.run
      end
    end

    let(:appropriate_body) { FactoryBot.create(:appropriate_body) }

    let!(:teacher_1) do
      teacher = FactoryBot.create(:teacher, trs_first_name: "Alice", trs_last_name: "Smith", trn: "1234567")
      FactoryBot.create(:induction_period, :active, teacher:, appropriate_body:, started_on: Date.new(2024, 3, 15))
      teacher
    end

    let!(:teacher_2) do
      teacher = FactoryBot.create(:teacher, trs_first_name: "Bob", trs_last_name: "Jones", trn: "2345678")
      FactoryBot.create(:induction_period, :active, teacher:, appropriate_body:, started_on: Date.new(2024, 4, 1))
      teacher
    end

    let(:teachers) { [teacher_1, teacher_2] }

    it 'renders the teachers table' do
      expect(rendered.css('table').length).to eq(1)
    end

    it 'renders table headers' do
      headers = rendered.css('th').map(&:text)
      expect(headers).to include('Name')
      expect(headers).to include('TRN')
      expect(headers).to include('Induction start date')
      expect(headers).to include('Status')
    end

    it 'renders table with correct styling' do
      table = rendered.css('table').first
      expect(table['class']).to be_present
    end

    it 'renders teacher data in table rows' do
      # Should render one row for each teacher
      expect(rendered.css('tbody tr').length).to eq(2)
    end

    it 'renders teacher names as links' do
      expect(rendered.css('tbody td a').length).to eq(2) # One link per teacher
    end

    it 'renders TRN data' do
      expect(rendered.to_html).to include('1234567')
      expect(rendered.to_html).to include('2345678')
    end

    it 'renders pagination component' do
      # Pagy should render pagination elements in the HTML
      expect(rendered.to_html).to include('pagination')
    end

    it 'uses proper table markup' do
      expect(rendered.css('thead').length).to eq(1)
      expect(rendered.css('tbody').length).to eq(1)
    end

    it 'renders within grid layout' do
      expect(rendered.css('.govuk-grid-row .govuk-grid-column-full').length).to eq(1)
    end
  end

  context 'with no teachers' do
    let(:teachers) { [] }

    context 'without search query' do
      let(:query) { nil }

      it 'does not render table' do
        expect(rendered.css('table').length).to eq(0)
      end

      it 'renders empty state message' do
        expect(rendered.to_html).to include('No open inductions found.')
      end

      it 'does not render pagination' do
        expect(rendered.to_html).not_to include('pagination')
        expect(rendered.css('.pagy').length).to eq(0)
      end

      it 'renders empty message in paragraph' do
        expect(rendered.css('p.govuk-body').length).to eq(1)
      end
    end

    context 'with search query' do
      let(:query) { 'John Doe' }

      it 'does not render empty state message when there is a search query' do
        expect(rendered.to_html).not_to include('No open inductions found matching')
        expect(rendered.to_html).not_to include('John Doe')
        expect(rendered.css('p.govuk-body').length).to eq(0)
      end

      it 'does not render table either' do
        expect(rendered.css('table').length).to eq(0)
      end
    end

    context 'with closed status' do
      let(:status) { 'closed' }

      it 'renders correct empty message for closed inductions' do
        expect(rendered.to_html).to include('No closed inductions found.')
      end
    end
  end

  describe 'component behavior' do
    let(:teachers) { [] }

    it 'includes necessary helpers' do
      expect(component.class.included_modules).to include(GovukLinkHelper)
      expect(component.class.included_modules).to include(Pagy::Frontend)
      expect(component.class.included_modules).to include(Rails.application.routes.url_helpers)
      expect(component.class.included_modules).to include(EmptyStateMessage)
    end

    describe '#teachers_present?' do
      context 'with teachers' do
        let(:teachers) { [double("Teacher")] }

        it 'returns true' do
          expect(component.send(:teachers_present?)).to be(true)
        end
      end

      context 'without teachers' do
        let(:teachers) { [] }

        it 'returns false' do
          expect(component.send(:teachers_present?)).to be(false)
        end
      end
    end

    describe '#empty_state_message' do
      context 'without query' do
        let(:query) { nil }

        context 'with open status' do
          let(:status) { 'open' }

          it 'returns correct message' do
            expect(component.send(:empty_state_message)).to eq('No open inductions found.')
          end
        end

        context 'with closed status' do
          let(:status) { 'closed' }

          it 'returns correct message' do
            expect(component.send(:empty_state_message)).to eq('No closed inductions found.')
          end
        end
      end

      context 'with query' do
        let(:query) { 'Alice Smith' }
        let(:status) { 'open' }

        it 'returns message with highlighted query' do
          expected_message = 'No open inductions found matching "<strong class="govuk-!-font-weight-bold">Alice Smith</strong>".'
          expect(component.send(:empty_state_message)).to eq(expected_message)
        end
      end

      context 'with special characters in query' do
        let(:query) { "O'Connor & <test>" }
        let(:status) { 'open' }

        it 'properly escapes special characters' do
          message = component.send(:empty_state_message)
          expect(message).to include('<strong class="govuk-!-font-weight-bold">O&#39;Connor &amp; &lt;test&gt;</strong>')
        end
      end
    end

    describe 'helper methods' do
      let(:teacher) { double("Teacher", trn: "1234567", induction_periods: [], trs_induction_status: nil) }

      describe '#teacher_full_name' do
        it 'delegates to Teachers::Name service' do
          name_service = double("Teachers::Name")
          allow(Teachers::Name).to receive(:new).with(teacher).and_return(name_service)
          allow(name_service).to receive(:full_name).and_return("John Doe")

          expect(component.send(:teacher_full_name, teacher)).to eq("John Doe")
        end
      end

      describe '#teacher_induction_start_date' do
        it 'delegates to Teachers::InductionPeriod service' do
          period_service = double("Teachers::InductionPeriod")
          allow(Teachers::InductionPeriod).to receive(:new).with(teacher).and_return(period_service)
          allow(period_service).to receive(:formatted_induction_start_date).and_return("1 January 2024")

          expect(component.send(:teacher_induction_start_date, teacher)).to eq("1 January 2024")
        end
      end

      describe '#teacher_status_tag_kwargs' do
        it 'delegates to Teachers::InductionStatus service' do
          status_service = double("Teachers::InductionStatus")
          expected_kwargs = { text: "Active", colour: "green" }

          allow(Teachers::InductionStatus).to receive(:new).with(
            teacher:,
            induction_periods: teacher.induction_periods,
            trs_induction_status: teacher.trs_induction_status
          ).and_return(status_service)
          allow(status_service).to receive(:status_tag_kwargs).and_return(expected_kwargs)

          expect(component.send(:teacher_status_tag_kwargs, teacher)).to eq(expected_kwargs)
        end
      end
    end
  end

  describe 'teacher data integration' do
    around do |example|
      travel_to(Date.new(2024, 6, 15)) do
        example.run
      end
    end

    let(:appropriate_body) { FactoryBot.create(:appropriate_body) }

    let!(:integration_teacher) do
      teacher = FactoryBot.create(:teacher, trs_first_name: "Alice", trs_last_name: "Smith", trn: "1234567")
      FactoryBot.create(:induction_period, :active, teacher:, appropriate_body:, started_on: Date.new(2024, 3, 15))
      teacher
    end

    let(:teachers) { [integration_teacher] }

    it 'displays teacher full name using Teachers::Name service' do
      expect(rendered.to_html).to include('Alice Smith')
    end

    it 'displays TRN directly from teacher record' do
      expect(rendered.to_html).to include('1234567')
    end

    it 'displays formatted induction start date using Teachers::InductionPeriod service' do
      expect(rendered.css('tbody td').map(&:text)).to include('15 March 2024')
    end

    it 'displays induction status using Teachers::InductionStatus service' do
      # The service will determine status from actual teacher data
      expect(rendered.css('.govuk-tag').length).to eq(1)
    end
  end

  describe 'edge cases' do
    context 'with empty string query' do
      let(:teachers) { [] }
      let(:query) { '' }

      it 'treats empty string as no query' do
        expect(rendered.to_html).to include('No open inductions found.')
        expect(rendered.to_html).not_to include('matching')
      end
    end

    context 'with very long query' do
      let(:teachers) { [] }
      let(:query) { 'A' * 100 }

      it 'handles long queries without error' do
        expect { rendered }.not_to raise_error
        # No empty state message should be shown when there's a query
        expect(rendered.to_html).not_to include('matching')
      end
    end
  end
end
