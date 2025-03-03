RSpec.describe 'schools/ects/show.html.erb' do
  let(:back_path) { schools_ects_home_path }

  let(:teacher) { FactoryBot.create(:teacher, trs_first_name: 'Barry', trs_last_name: 'White') }
  let(:school_1) { FactoryBot.create(:school, urn: '123456') }
  let(:school_2) { FactoryBot.create(:school, urn: '987654') }

  before do
    FactoryBot.create(:ect_at_school_period,
                      started_on: '2024-01-11',
                      finished_on: '2025-01-11',
                      teacher:,
                      school: school_1,
                      working_pattern: 'part_time',
                      email: 'previous-address@whale.com')
  end

  let!(:current_ect_period) do
    FactoryBot.create(:ect_at_school_period,
                      started_on: '2025-01-11',
                      finished_on: nil,
                      teacher:,
                      school: school_2,
                      working_pattern: 'full_time',
                      email: 'love@whale.com')
  end

  before do
    assign(:ect, current_ect_period)
    render
  end

  it 'has title' do
    expect(view.content_for(:page_title)).to eql('Barry White')
  end

  it 'includes a back button that links to the school home page' do
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link('Back', href: back_path)
  end

  describe 'personal details summary' do
    it 'title' do
      expect(rendered).to have_css('h2.govuk-heading-m', text: 'Personal details')
    end

    it 'full name' do
      expect(rendered).to have_css('dt.govuk-summary-list__key', text: 'Name')
      expect(rendered).to have_css('dd.govuk-summary-list__value', text: 'Barry White')
    end

    describe 'mentor' do
      context 'when assigned' do
        before do
          mentor = FactoryBot.create(:teacher, trs_first_name: 'Moby', trs_last_name: 'Dick')
          mentor_at_school_period = FactoryBot.create(:mentor_at_school_period, :active, school: school_2, teacher: mentor)

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

  describe 'current training details summary card' do
    before do
      academic_year = FactoryBot.create(:academic_year)
      lead_provider = FactoryBot.create(:lead_provider, name: 'Ambition institute')
      delivery_partner = FactoryBot.create(:delivery_partner)
      provider_partnership = FactoryBot.create(:provider_partnership, lead_provider:, delivery_partner:, academic_year:)
      appropriate_body = FactoryBot.create(:appropriate_body, name: 'Alpha Teaching School Hub')

      FactoryBot.create(:training_period, :active, :for_ect, provider_partnership:,
                                                             ect_at_school_period: current_ect_period,
                                                             started_on: current_ect_period.started_on)

      FactoryBot.create(:induction_period, :active, teacher:, appropriate_body:)

      render
    end

    it 'title' do
      expect(rendered).to have_css('h2.govuk-summary-card__title', text: 'Current training details')
    end

    it 'appropriate body' do
      expect(rendered).to have_css('dt.govuk-summary-list__key', text: 'Appropriate body')
      expect(rendered).to have_css('dd.govuk-summary-list__value', text: 'Alpha Teaching School Hub')
    end

    it 'programme type' do
      expect(rendered).to have_css('dt.govuk-summary-list__key', text: 'Programme type')
      expect(rendered).to have_css('dd.govuk-summary-list__value', text: 'Full induction programme')
    end

    it 'lead provider' do
      expect(rendered).to have_css('dt.govuk-summary-list__key', text: 'Lead provider')
      expect(rendered).to have_css('dd.govuk-summary-list__value', text: 'Ambition institute')
    end
  end
end
