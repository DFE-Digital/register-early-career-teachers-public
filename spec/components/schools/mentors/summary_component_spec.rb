RSpec.describe Schools::Mentors::SummaryComponent, type: :component do
  let(:school) { create(:school) }
  let(:mentor_teacher) { create(:teacher, trs_first_name: 'Naruto', trs_last_name: 'Uzumaki') }
  let(:started_on) { Date.new(2023, 9, 1) }
  let(:mentor) { create(:mentor_at_school_period, teacher: mentor_teacher, school:, started_on:, finished_on: nil) }

  context 'with no ECTs' do
    it 'shows No ECTs assigned' do
      render_inline(described_class.new(mentor:, school:))
      expect(rendered_content).to have_css('.govuk-summary-list__row', text: 'Assigned ECTs')
      expect(rendered_content).to have_css('.govuk-summary-list__value', text: 'No ECTs assigned')
    end
  end

  context 'with less than or equal to 5 ECTs' do
    let!(:ects) do
      create_list(:teacher, 5).map do |teacher|
        ect = create(:ect_at_school_period, teacher:, school:, started_on:, finished_on: nil)
        create(:mentorship_period, mentor:, mentee: ect, started_on:, finished_on: nil)
        teacher
      end
    end

    it 'lists ECT names' do
      render_inline(described_class.new(mentor:, school:))

      ects.each do |teacher|
        expect(rendered_content).to have_css('.govuk-summary-list__value', text: "#{teacher.trs_first_name} #{teacher.trs_last_name}")
      end
    end
  end

  context 'with more than 5 ECTs' do
    before do
      create_list(:teacher, 6).each do |teacher|
        ect = create(:ect_at_school_period, teacher:, school:, started_on:, finished_on: nil)
        create(:mentorship_period, mentor:, mentee: ect, started_on:, finished_on: nil)
      end
    end

    it 'shows ECT count instead of listing names' do
      render_inline(described_class.new(mentor:, school:))
      expect(rendered_content).to have_css('.govuk-summary-list__value', text: '6 assigned ECTs')
    end
  end

  context 'when there are multiple mentors' do
    let(:mentor2_teacher) { create(:teacher, trs_first_name: 'Sasuke', trs_last_name: 'Uchiha') }
    let(:mentor2) { create(:mentor_at_school_period, :active, teacher: mentor2_teacher, school:, started_on:) }

    let(:ect1_teacher) { create(:teacher, trs_first_name: 'Konohamaru', trs_last_name: 'Sarutobi') }
    let(:ect2_teacher) { create(:teacher, trs_first_name: 'Boruto', trs_last_name: 'Uzumaki') }

    let(:ect1) { create(:ect_at_school_period, teacher: ect1_teacher, school:, started_on:, finished_on: nil) }
    let(:ect2) { create(:ect_at_school_period, teacher: ect2_teacher, school:, started_on:, finished_on: nil) }

    before do
      create(:mentorship_period, mentor:, mentee: ect1, started_on:, finished_on: nil)
      create(:mentorship_period, mentor: mentor2, mentee: ect2, started_on:, finished_on: nil)
    end

    it 'only shows ECTs assigned to the specific mentor' do
      render_inline(described_class.new(mentor:, school:))
      expect(rendered_content).to have_css('.govuk-summary-list__value', text: 'Konohamaru Sarutobi')
      expect(rendered_content).not_to have_css('.govuk-summary-list__value', text: 'Boruto Uzumaki')
    end
  end
end
