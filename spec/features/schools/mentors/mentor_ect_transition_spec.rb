RSpec.describe 'Mentor ECT assignments during school transitions' do
  let(:old_school) do
    FactoryBot.create(:school) do |school|
      school.gias_school.update!(name: 'Old School')
    end
  end
  let(:new_school) do
    FactoryBot.create(:school) do |school|
      school.gias_school.update!(name: 'New School')
    end
  end
  let(:ect) { FactoryBot.create(:teacher, trs_first_name: 'John', trs_last_name: 'Doe') }
  let(:old_mentor) { FactoryBot.create(:teacher, trs_first_name: 'Jane', trs_last_name: 'Smith') }
  let(:new_mentor) { FactoryBot.create(:teacher, trs_first_name: 'Bob', trs_last_name: 'Wilson') }
  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }

  let(:old_school_start_date) { 2.months.ago }
  let(:old_school_end_date) { 1.week.ago }
  let(:transition_date) { Date.current }

  # Set up ECT at old school with mentor (already finished)
  let!(:old_ect_period) do
    FactoryBot.create(:ect_at_school_period,
                      school: old_school,
                      teacher: ect,
                      started_on: old_school_start_date,
                      finished_on: old_school_end_date,
                      school_reported_appropriate_body: appropriate_body)
  end

  let!(:old_mentor_period) do
    FactoryBot.create(:mentor_at_school_period,
                      school: old_school,
                      teacher: old_mentor,
                      started_on: old_school_start_date,
                      finished_on: old_school_end_date)
  end

  let!(:mentorship_period) do
    FactoryBot.create(:mentorship_period,
                      mentee: old_ect_period,
                      mentor: old_mentor_period,
                      started_on: old_school_start_date,
                      finished_on: old_school_end_date)
  end

  describe 'Before ECT transition date' do
    context 'when ECT has future period at new school' do
      let!(:future_ect_period) do
        FactoryBot.create(:ect_at_school_period,
                          school: new_school,
                          teacher: ect,
                          started_on: transition_date,
                          finished_on: nil,
                          school_reported_appropriate_body: appropriate_body)
      end

      scenario 'New school does not see old mentor assignment' do
        sign_in_as_school_user(school: new_school)
        page.goto(schools_mentors_path)

        # Old mentor should not appear in new school's mentor list
        expect(page.get_by_text('Jane Smith')).not_to be_visible
      end
    end
  end

  describe 'After ECT transition date' do
    context 'when ECT has moved to new school' do
      let!(:new_ect_period) do
        FactoryBot.create(:ect_at_school_period,
                          school: new_school,
                          teacher: ect,
                          started_on: transition_date,
                          finished_on: nil,
                          school_reported_appropriate_body: appropriate_body)
      end

      let!(:new_mentor_period) do
        FactoryBot.create(:mentor_at_school_period,
                          school: new_school,
                          teacher: new_mentor,
                          started_on: transition_date,
                          finished_on: nil)
      end

      let!(:new_mentorship_period) do
        FactoryBot.create(:mentorship_period,
                          mentee: new_ect_period,
                          mentor: new_mentor_period,
                          started_on: transition_date,
                          finished_on: nil)
      end

      scenario 'Old school mentor no longer sees ECT in assigned list' do
        sign_in_as_school_user(school: old_school)
        page.goto(schools_mentors_path)

        # Find the old mentor
        expect(page.get_by_text('Jane Smith')).to be_visible
        page.get_by_role('link', name: 'Jane Smith').click

        # Mentor should not see the ECT anymore (mentorship has ended)
        expect(page.get_by_text('John Doe')).not_to be_visible
      end

      scenario 'New school mentor sees assigned ECT' do
        sign_in_as_school_user(school: new_school)
        page.goto(schools_mentors_path)

        # Find the new mentor
        expect(page.get_by_text('Bob Wilson')).to be_visible
        page.get_by_role('link', name: 'Bob Wilson').click

        # New mentor should see their assigned ECT
        expect(page.get_by_text('Assigned ECTs')).to be_visible
        expect(page.get_by_text('John Doe')).to be_visible
      end
    end
  end

  describe 'Mentor assignment visibility edge cases' do
    context 'when ECT has no mentor at new school initially' do
      let!(:new_ect_period_no_mentor) do
        FactoryBot.create(:ect_at_school_period,
                          school: new_school,
                          teacher: ect,
                          started_on: transition_date,
                          finished_on: nil,
                          school_reported_appropriate_body: appropriate_body)
      end

      let!(:new_training_period_no_mentor) do
        FactoryBot.create(:training_period,
                          ect_at_school_period: new_ect_period_no_mentor,
                          started_on: transition_date,
                          finished_on: nil,
                          training_programme: 'school_led')
      end

      scenario 'ECT appears in new school ECT list without mentor assignment' do
        sign_in_as_school_user(school: new_school)
        page.goto(schools_ects_path)

        # ECT should appear in list
        expect(page.get_by_text('John Doe')).to be_visible

        # Click on ECT to see details
        page.get_by_role('link', name: 'John Doe').click

        # ECT should be visible but without mentor assignment
        expect(page.get_by_role('heading', name: 'John Doe')).to be_visible
      end
    end
  end
end
