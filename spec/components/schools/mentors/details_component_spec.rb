RSpec.describe Schools::Mentors::DetailsComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:school) { FactoryBot.create(:school) }
  let(:mentor_teacher) { FactoryBot.create(:teacher, trs_first_name: 'Naruto', trs_last_name: 'Uzumaki') }
  let(:started_on) { Date.new(2023, 9, 1) }

  let(:mentor) do
    FactoryBot.create(:mentor_at_school_period,
                      teacher: mentor_teacher,
                      school:,
                      started_on:,
                      finished_on: nil)
  end

  let(:ect_teacher_1) { FactoryBot.create(:teacher, trs_first_name: 'Konohamaru', trs_last_name: 'Sarutobi') }
  let(:ect_teacher_2) { FactoryBot.create(:teacher, trs_first_name: 'Boruto', trs_last_name: 'Uzumaki') }

  let(:ect_period_1) do
    FactoryBot.create(:ect_at_school_period,
                      teacher: ect_teacher_1,
                      school:,
                      started_on:,
                      finished_on: nil)
  end

  let(:ect_period_2) do
    FactoryBot.create(:ect_at_school_period,
                      teacher: ect_teacher_2,
                      school:,
                      started_on:,
                      finished_on: nil)
  end

  context 'when there are ECTs assigned to the mentor' do
    before do
      FactoryBot.create(:mentorship_period, mentor:, mentee: ect_period_1, started_on:, finished_on: nil)
      FactoryBot.create(:mentorship_period, mentor:, mentee: ect_period_2, started_on:, finished_on: nil)

      render_inline(described_class.new(teacher: mentor_teacher, mentor:))
    end

    it 'renders the section heading' do
      expect(page).to have_css('h2.govuk-heading-m', text: 'Mentor details')
    end

    it 'shows the mentors name' do
      expect(page).to have_css('.govuk-summary-list__value', text: 'Naruto Uzumaki')
    end

    it 'shows the mentors email address' do
      expect(page).to have_css('.govuk-summary-list__value', text: mentor.email)
    end

    it 'renders links for assigned ECTs' do
      within('.govuk-summary-list__value') do
        expect(page).to have_link(
          'Konohamaru Sarutobi',
          href: schools_ect_path(ect_period_1, back_to_mentor: true, mentor_id: mentor.id)
        )

        expect(page).to have_link(
          'Boruto Uzumaki',
          href: schools_ect_path(ect_period_2, back_to_mentor: true, mentor_id: mentor.id)
        )
      end
    end
  end

  context 'when there are ECTs not assigned to this mentor' do
    let(:other_teacher) { FactoryBot.create(:teacher, trs_first_name: 'Kakashi', trs_last_name: 'Hatake') }
    let(:other_mentor) do
      FactoryBot.create(:mentor_at_school_period, teacher: other_teacher, school:, started_on:, finished_on: nil)
    end
    let(:unrelated_ect_teacher) { FactoryBot.create(:teacher, trs_first_name: 'Sauske', trs_last_name: 'Uchiha') }
    let(:unrelated_ect) do
      FactoryBot.create(:ect_at_school_period, teacher: unrelated_ect_teacher, school:, started_on:, finished_on: nil)
    end

    before do
      FactoryBot.create(:mentorship_period, mentor: other_mentor, mentee: unrelated_ect, started_on:, finished_on: nil)
      render_inline(described_class.new(teacher: mentor_teacher, mentor:))
    end

    it 'does not render ECTs assigned to other mentors' do
      expect(page).not_to have_css('.govuk-summary-list__value', text: 'Sauske Uchiha')
    end
  end

  context 'when there are no ECTs assigned to the mentor' do
    before do
      render_inline(described_class.new(teacher: mentor_teacher, mentor:))
    end

    it 'renders the no ECTS assigned text' do
      expect(page).to have_css('.govuk-summary-list__value', text: 'No ECTs assigned')
    end
  end
end
