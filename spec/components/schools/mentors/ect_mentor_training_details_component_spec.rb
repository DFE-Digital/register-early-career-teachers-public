RSpec.describe Schools::Mentors::ECTMentorTrainingDetailsComponent, type: :component do
  let(:school) { create(:school) }
  let(:mentor) { create(:mentor_at_school_period, teacher:, school:) }
  let(:teacher) { create(:teacher, mentor_completion_date: nil) }

  context 'when teacher is eligible and there is a provider-led ECT' do
    let(:provider_led_ect) { create(:ect_at_school_period, programme_type: 'provider_led', school:) }

    it 'renders the summary cards' do
      render_inline(described_class.new(teacher:, mentor:, ects: [provider_led_ect]))

      expect(rendered_content).to have_css('h2', text: 'ECT mentor training details')
      expect(rendered_content).to have_text('Reported to us by your school')
      expect(rendered_content).to have_text('Reported to us by your lead provider')
    end
  end

  context 'when teacher is not eligible' do
    let(:teacher) { create(:teacher, mentor_completion_date: Date.new(2024, 1, 1)) }
    let(:provider_led_ect) { create(:ect_at_school_period, programme_type: 'provider_led', school:) }

    it 'renders the ineligible message' do
      render_inline(described_class.new(teacher:, mentor:, ects: [provider_led_ect]))

      expect(rendered_content).to have_css('.govuk-body', text: /cannot do ECTE mentor training according to our records/)
    end
  end

  context 'when all ECTs are school-led' do
    let(:school_led_ect) { create(:ect_at_school_period, programme_type: 'school_led', lead_provider: nil, school:) }

    it 'does not render' do
      component = described_class.new(teacher:, mentor:, ects: [school_led_ect])

      expect(component.render?).to be false
    end
  end
end
