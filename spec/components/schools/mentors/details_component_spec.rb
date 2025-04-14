RSpec.describe Schools::Mentors::DetailsComponent, type: :component do
  include Rails.application.routes.url_helpers

  before do
    render_inline(described_class.new(teacher: mentor_teacher, mentor:, ects:))
  end

  let(:school) { create(:school) }
  let(:mentor_teacher) { create(:teacher, trs_first_name: 'Naruto', trs_last_name: 'Uzumaki') }
  let(:mentor) { create(:mentor_at_school_period, teacher: mentor_teacher, school:) }

  let(:ect_teacher_1) { create(:teacher, trs_first_name: 'Konohamaru', trs_last_name: 'Sarutobi') }
  let(:ect_teacher_2) { create(:teacher, trs_first_name: 'Boruto', trs_last_name: 'Uzumaki') }

  let(:ect_period_1) { create(:ect_at_school_period, teacher: ect_teacher_1, school:) }
  let(:ect_period_2) { create(:ect_at_school_period, teacher: ect_teacher_2, school:) }

  let(:ects) { [ect_period_1, ect_period_2] }

  it 'renders the section heading' do
    expect(page).to have_css('h2.govuk-heading-m', text: 'Mentor details')
  end

  it 'shows the mentors name' do
    expect(page).to have_text('Naruto Uzumaki')
  end

  it 'shows the mentors email address' do
    expect(page).to have_text(mentor.email)
  end

  it 'renders links for assigned ECTs' do
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
