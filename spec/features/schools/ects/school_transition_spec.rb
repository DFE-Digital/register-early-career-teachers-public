RSpec.describe 'ECT school transitions' do
  include_context 'test trs api client'

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
  let(:teacher) { FactoryBot.create(:teacher, trs_first_name: 'John', trs_last_name: 'Doe') }
  let(:mentor) { FactoryBot.create(:teacher, trs_first_name: 'Jane', trs_last_name: 'Smith') }
  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let(:lead_provider) { FactoryBot.create(:lead_provider) }
  let!(:contract_period) { FactoryBot.create(:contract_period, year: 2024) }
  let!(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:, contract_period:) }

  let(:old_school_start_date) { 2.months.ago }
  let(:old_school_end_date) { 1.week.ago }
  let(:new_school_start_date) { Date.current }

  # Set up existing ECT at old school (already finished)
  let!(:old_ect_period) do
    FactoryBot.create(:ect_at_school_period,
                      school: old_school,
                      teacher:,
                      started_on: old_school_start_date,
                      finished_on: old_school_end_date,
                      email: 'john.old@example.com',
                      working_pattern: 'full_time',
                      school_reported_appropriate_body: appropriate_body)
  end

  let!(:old_training_period) do
    FactoryBot.create(:training_period,
                      ect_at_school_period: old_ect_period,
                      started_on: old_school_start_date,
                      finished_on: old_school_end_date,
                      training_programme: 'provider_led')
  end

  let!(:mentor_period) do
    FactoryBot.create(:mentor_at_school_period,
                      school: old_school,
                      teacher: mentor,
                      started_on: old_school_start_date,
                      finished_on: old_school_end_date)
  end

  let!(:mentorship_period) do
    FactoryBot.create(:mentorship_period,
                      mentee: old_ect_period,
                      mentor: mentor_period,
                      started_on: old_school_start_date,
                      finished_on: old_school_end_date)
  end

  describe 'After ECT has transitioned to new school' do
    context 'when ECT has finished at old school and started at new school' do
      # Create current ECT period at new school (simulating completed school transition)
      let!(:new_ect_period) do
        FactoryBot.create(:ect_at_school_period,
                          school: new_school,
                          teacher:,
                          started_on: new_school_start_date,
                          finished_on: nil,
                          email: 'john.new@example.com',
                          working_pattern: 'part_time',
                          school_reported_appropriate_body: appropriate_body)
      end

      let!(:new_training_period) do
        FactoryBot.create(:training_period,
                          ect_at_school_period: new_ect_period,
                          started_on: new_school_start_date,
                          finished_on: nil,
                          training_programme: 'school_led')
      end

      scenario 'AC 2b: Old school no longer sees ECT anywhere' do
        sign_in_as_school_user(school: old_school)
        page.goto(schools_ects_path)

        # ECT should not be visible in old school's list (period has finished)
        expect(page.get_by_text('John Doe')).not_to be_visible
        expect(page.get_by_text('john.old@example.com')).not_to be_visible
      end

      scenario 'AC 2c: New school sees ECT with new registration details' do
        sign_in_as_school_user(school: new_school)
        page.goto(schools_ects_path)

        # ECT should be visible in new school's list
        expect(page.get_by_text('John Doe')).to be_visible

        # Click on ECT to see details
        page.get_by_role('link', name: 'John Doe').click

        # Verify new registration details on the detail page
        expect(page.get_by_role('heading', name: 'John Doe')).to be_visible
        expect(page.get_by_text('john.new@example.com')).to be_visible # New email
        expect(page.get_by_text('Part time')).to be_visible # New working pattern
        expect(page.get_by_text(new_school_start_date.to_fs(:govuk))).to be_visible # New start date
        expect(page.get_by_text(appropriate_body.name)).to be_visible # New AB choice
        expect(page.get_by_text('School-led')).to be_visible # New training programme
      end

      scenario 'Old school mentor no longer sees ECT in assigned list' do
        sign_in_as_school_user(school: old_school)
        page.goto(schools_mentors_path)

        # Find and click on mentor
        page.get_by_role('link', name: 'Jane Smith').click

        # Mentor should no longer see the ECT (mentorship period has ended)
        expect(page.get_by_text('John Doe')).not_to be_visible
      end
    end
  end
end
