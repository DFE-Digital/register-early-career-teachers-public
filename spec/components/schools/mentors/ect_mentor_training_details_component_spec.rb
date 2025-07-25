RSpec.describe Schools::Mentors::ECTMentorTrainingDetailsComponent, type: :component do
  let(:school) { FactoryBot.create(:school) }
  let(:mentor_start_date) { Date.new(2023, 1, 1) }
  let(:mentor) { FactoryBot.create(:mentor_at_school_period, teacher:, school:, started_on: mentor_start_date, finished_on: nil) }
  let(:teacher) { FactoryBot.create(:teacher, mentor_became_ineligible_for_funding_on: nil) }

  context 'when teacher is eligible and there is a provider-led ECT with a lead provider' do
    let(:lead_provider) { FactoryBot.create(:lead_provider, name: 'Hidden leaf village') }
    let(:ect_teacher) { FactoryBot.create(:teacher) }
    let(:ect_start_date) { mentor_start_date + 1.month }
    let(:ect) do
      FactoryBot.create(:ect_at_school_period,
                        :with_training_period,
                        teacher: ect_teacher,
                        school:,
                        lead_provider:,
                        training_programme: 'provider_led',
                        started_on: ect_start_date,
                        finished_on: nil)
    end

    before do
      FactoryBot.create(:mentorship_period, mentor:, mentee: ect, started_on: ect_start_date, finished_on: nil)
    end

    it 'renders the summary cards' do
      render_inline(described_class.new(teacher:, mentor:))
      expect(rendered_content).to have_css('h2', text: 'ECTE mentor training details')
      expect(rendered_content).to have_text('Reported to us by your school')
      expect(rendered_content).to have_text('Reported to us by your lead provider')
    end

    it 'shows the lead provider name from the first provider-led ECT' do
      render_inline(described_class.new(teacher:, mentor:))
      expect(rendered_content).to have_text("Hidden leaf village")
    end
  end

  context 'when teacher is not eligible' do
    let(:teacher) { FactoryBot.create(:teacher, :ineligible_for_mentor_funding) }
    let(:ect_teacher) { FactoryBot.create(:teacher) }
    let(:ect_start_date) { mentor_start_date + 1.month }
    let(:ect) do
      FactoryBot.create(:ect_at_school_period,
                        teacher: ect_teacher,
                        school:,
                        training_programme: 'provider_led',
                        started_on: ect_start_date,
                        finished_on: nil)
    end

    before do
      FactoryBot.create(:mentorship_period, mentor:, mentee: ect, started_on: ect_start_date, finished_on: nil)
    end

    it 'renders the ineligible message' do
      render_inline(described_class.new(teacher:, mentor:))
      expect(rendered_content).to have_css('.govuk-body', text: /cannot do ECTE mentor training according to our records/)
    end
  end

  context 'when all ECTs are school-led' do
    let(:ect_teacher) { FactoryBot.create(:teacher) }
    let(:school_led_ect) do
      FactoryBot.create(:ect_at_school_period,
                        teacher: ect_teacher,
                        school:,
                        training_programme: 'school_led',
                        started_on: mentor_start_date + 1.month,
                        finished_on: nil)
    end

    before do
      FactoryBot.create(:mentorship_period, mentor:, mentee: school_led_ect, started_on: school_led_ect.started_on, finished_on: nil)
    end

    it 'does not render' do
      component = described_class.new(teacher:, mentor:)
      expect(component.render?).to be false
      render_inline(component)
      expect(rendered_content).to be_empty
    end
  end
end
