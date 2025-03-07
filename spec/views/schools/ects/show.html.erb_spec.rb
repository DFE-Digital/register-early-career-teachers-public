RSpec.describe 'schools/ects/show.html.erb' do
  let(:academic_year) { FactoryBot.create(:academic_year) }
  let(:appropriate_body_type) { :teaching_school_hub }
  let(:lead_provider) { FactoryBot.create(:lead_provider, name: 'Ambition institute') }
  let(:delivery_partner) { FactoryBot.create(:delivery_partner) }
  let(:provider_partnership) { FactoryBot.create(:provider_partnership, lead_provider:, delivery_partner:, academic_year:) }
  let(:appropriate_body) { FactoryBot.create(:appropriate_body, name: 'Alpha Teaching School Hub') }
  let(:teacher) { FactoryBot.create(:teacher, trs_first_name: 'Barry', trs_last_name: 'White', corrected_name: 'Baz White') }
  let(:previous_school) { FactoryBot.create(:school, urn: '123456') }
  let(:current_school) { FactoryBot.create(:school, :state_funded, urn: '987654') }
  let(:requested_lead_provider) { FactoryBot.create(:lead_provider, name: 'Requested LP') }
  let(:requested_appropriate_body) { FactoryBot.create(:appropriate_body, name: 'Requested AB') }
  let(:programme_type) { 'provider_led' }

  before do
    FactoryBot.create(:ect_at_school_period, teacher:,
                                             started_on: '2024-01-11',
                                             finished_on: '2025-01-11',
                                             school: previous_school,
                                             email: 'previous-address@whale.com')
  end

  let!(:current_ect_period) do
    FactoryBot.create(:ect_at_school_period,
                      appropriate_body_type,
                      teacher:,
                      started_on: '2025-01-11',
                      finished_on: nil,
                      lead_provider: requested_lead_provider,
                      appropriate_body: requested_appropriate_body,
                      school: current_school,
                      working_pattern: 'full_time',
                      programme_type:,
                      email: 'love@whale.com')
  end

  before do
    assign(:ect, current_ect_period)
    render
  end

  it 'has title' do
    expect(view.content_for(:page_title)).to eql('Baz White')
  end

  it 'includes a back button that links to the school home page' do
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link('Back', href: schools_ects_home_path)
  end

  describe 'ECT details' do
    it 'title' do
      expect(rendered).to have_css('h2.govuk-heading-m', text: 'ECT details')
    end

    it 'full name' do
      expect(rendered).to have_css('dt.govuk-summary-list__key', text: 'Name')
      expect(rendered).to have_css('dd.govuk-summary-list__value', text: 'Baz White')
    end

    it 'current email address' do
      expect(rendered).to have_css('dt.govuk-summary-list__key', text: 'Email address')
      expect(rendered).to have_css('dd.govuk-summary-list__value', text: 'love@whale.com')
    end

    describe 'mentor' do
      context 'when assigned' do
        before do
          mentor = FactoryBot.create(:teacher, trs_first_name: 'Moby', trs_last_name: 'Dick')
          mentor_at_school_period = FactoryBot.create(:mentor_at_school_period, :active, school: current_school, teacher: mentor)

          FactoryBot.create(:mentorship_period, :active,
                            started_on: current_ect_period.started_on,
                            mentee: current_ect_period,
                            mentor: mentor_at_school_period)

          render
        end

        it "has mentor's full name" do
          expect(rendered).to have_css('dt.govuk-summary-list__key', text: 'Mentor')
          expect(rendered).to have_css('dd.govuk-summary-list__value', text: 'Moby Dick')
        end
      end

      context 'when unassigned' do
        it 'has instruction to assign' do
          expect(rendered).to have_css('dt.govuk-summary-list__key', text: 'Mentor')
          expect(rendered).to have_css('dd.govuk-summary-list__value', text: 'You must assign a mentor or register a new one for this ECT.')
        end
      end
    end

    it 'school start date' do
      expect(rendered).to have_css('dt.govuk-summary-list__key', text: 'School start date')
      expect(rendered).to have_css('dd.govuk-summary-list__value', text: 'January 2025')
    end

    it 'working pattern' do
      expect(rendered).to have_css('dt.govuk-summary-list__key', text: 'Working pattern')
      expect(rendered).to have_css('dd.govuk-summary-list__value', text: 'Full time')
    end
  end

  describe 'ECTE training details' do
    before do
      FactoryBot.create(:training_period, :active, :for_ect, provider_partnership:,
                                                             ect_at_school_period: current_ect_period,
                                                             started_on: current_ect_period.started_on)

      FactoryBot.create(:induction_period, :active, teacher:, appropriate_body:)

      render
    end

    it 'titles' do
      expect(rendered).to have_css('h2.govuk-heading-m', text: 'ECTE training details')
      expect(rendered).to have_css('h2.govuk-summary-card__title', text: 'Reported to us by your school')
      expect(rendered).to have_css('h2.govuk-summary-card__title', text: 'Reported to us by your lead provider')
      expect(rendered).to have_css('h2.govuk-summary-card__title', text: 'Reported to us by your appropriate body')
    end

    it 'keys' do
      expect(rendered).to have_css('dt.govuk-summary-list__key', text: 'Appropriate body')
      expect(rendered).to have_css('dt.govuk-summary-list__key', text: 'Programme type')
      expect(rendered).to have_css('dt.govuk-summary-list__key', text: 'Lead provider')
      expect(rendered).to have_css('dt.govuk-summary-list__key', text: 'Delivery partner')
      expect(rendered).to have_css('dt.govuk-summary-list__key', text: 'Induction start date')
    end

    it 'values' do
      expect(rendered).to have_css('dd.govuk-summary-list__value', text: 'Alpha Teaching School Hub')
      expect(rendered).to have_css('dd.govuk-summary-list__value', text: 'Full induction programme')
      expect(rendered).to have_css('dd.govuk-summary-list__value', text: 'Ambition institute')
      expect(rendered).to have_css('dd.govuk-summary-list__value', text: 'Provider-led')
      expect(rendered).to have_css('dd.govuk-summary-list__value', text: 1.year.ago.to_date.to_fs(:govuk))
      expect(rendered).to have_css('dd.govuk-summary-list__value', text: 'Requested LP')
      expect(rendered).to have_css('dd.govuk-summary-list__value', text: 'Requested AB')
    end

    context 'when school-led' do
      let(:programme_type) { 'school_led' }
      let(:requested_lead_provider) { nil }

      it 'hides Lead Provider' do
        expect(rendered).not_to have_css('dd.govuk-summary-list__value', text: 'Requested LP')
      end
    end

    context 'when school is independent' do
      let(:current_school) { FactoryBot.create(:school, :independent, urn: '987654') }
      let(:requested_appropriate_body) { nil }
      let(:appropriate_body_type) { :teaching_induction_panel }

      it 'replaces AB name with ISTIP' do
        expect(rendered).to have_css('dd.govuk-summary-list__value', text: 'Independent Schools Teacher Induction Panel (ISTIP)')
      end
    end
  end
end
