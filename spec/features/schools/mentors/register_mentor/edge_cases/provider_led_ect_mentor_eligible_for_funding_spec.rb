RSpec.describe 'Registering a mentor', :enable_schools_interface, :js do
  include_context 'test trs api client'
  include SchoolPartnershipHelpers

  let(:trn) { '3002586' }

  scenario 'mentor has existing mentorship, mentoring at new school only and is eligible for funding with provider-led ect' do
    given_there_is_a_school_in_the_service
    and_the_school_is_in_a_partnership_with_a_lead_provider
    and_there_is_an_ect_with_no_mentor_registered_at_the_school
    and_mentor_has_existing_mentorship_at_another_school
    and_i_sign_in_as_that_school_user
    and_i_am_on_the_schools_landing_page

    when_i_click_to_assign_a_mentor_to_the_ect
    then_i_am_in_the_requirements_page

    when_i_click_continue
    then_i_should_be_taken_to_the_find_mentor_page

    when_i_submit_the_find_mentor_form
    then_i_should_be_taken_to_the_review_mentor_details_page
    and_i_should_see_the_mentor_details_in_the_review_page

    when_i_select_that_my_mentor_name_is_incorrect
    and_i_enter_the_corrected_name
    and_i_click_confirm_and_continue
    then_i_should_be_taken_to_the_email_address_page

    when_i_enter_the_mentor_email_address
    and_i_click_continue
    then_i_should_be_taken_to_mentoring_at_your_school_only_page
    when_i_select_yes_they_will_be_mentoring_at_our_school_only

    then_i_should_be_taken_to_mentor_start_date_page
    when_i_enter_mentor_start_date
    and_i_click_continue

    then_i_should_be_taken_to_previous_training_period_details_page
    and_i_should_see_previous_training_period_details
    and_i_click_continue

    then_i_should_be_taken_to_programme_choices_page
    when_i_select_yes_use_same_programme_choices

    then_i_should_be_taken_to_the_check_answers_page
    and_i_should_see_all_the_mentor_data_on_the_page

    when_i_click_confirm_details
    then_i_should_be_taken_to_the_confirmation_page
    and_mentor_has_mentorship_with_new_school
  end

  def given_there_is_a_school_in_the_service
    @school = FactoryBot.create(:school, urn: "1234567")
  end

  def and_i_sign_in_as_that_school_user
    sign_in_as_school_user(school: @school)
  end

  def and_the_school_is_in_a_partnership_with_a_lead_provider
    @contract_period = FactoryBot.create(:contract_period, :with_schedules, :current)
    @school_partnership = make_partnership_for(@school, @contract_period)
    @lead_provider = @school_partnership.lead_provider_delivery_partnership.lead_provider
  end

  def and_there_is_an_ect_with_no_mentor_registered_at_the_school
    FactoryBot.create(:active_lead_provider, lead_provider: @lead_provider, contract_period: FactoryBot.create(:contract_period, year: Date.current.year))
    @ect = FactoryBot.create(:ect_at_school_period, :ongoing, school: @school)
    @training_period = FactoryBot.create(:training_period, :provider_led, :ongoing, ect_at_school_period: @ect, school_partnership: @school_partnership)
    @ect_name = Teachers::Name.new(@ect.teacher).full_name
  end

  def and_mentor_has_existing_mentorship_at_another_school
    another_school = FactoryBot.create(:school, urn: "7654321")
    @teacher = FactoryBot.create(:teacher, trn:, trs_first_name: 'Kirk', trs_last_name: 'Van Houten', corrected_name: nil)
    @existing_mentor_at_school_period = FactoryBot.create(:mentor_at_school_period, :ongoing, school: another_school, teacher: @teacher)
    another_school_partnership = FactoryBot.create(:school_partnership, lead_provider_delivery_partnership: @school_partnership.lead_provider_delivery_partnership, school: another_school)
    @training_period = FactoryBot.create(:training_period, :for_mentor, :ongoing, started_on: @existing_mentor_at_school_period.started_on, mentor_at_school_period: @existing_mentor_at_school_period, school_partnership: another_school_partnership)
  end

  def and_i_am_on_the_schools_landing_page
    path = '/school/home/ects'
    page.goto path
    expect(page).to have_path(path)
  end

  def when_i_click_to_assign_a_mentor_to_the_ect
    page.get_by_role('link', name: 'Assign a mentor for this ECT').click
  end

  def then_i_am_in_the_requirements_page
    expect(page.get_by_text("What you'll need to add a new mentor for #{@ect_name}")).to be_visible
    expect(page.url).to end_with("/school/register-mentor/what-you-will-need?ect_id=#{@ect.id}")
  end

  def when_i_click_continue
    page.get_by_role('link', name: 'Continue').click
  end

  def then_i_should_be_taken_to_the_find_mentor_page
    path = '/school/register-mentor/find-mentor'
    expect(page).to have_path(path)
  end

  def when_i_submit_the_find_mentor_form
    page.get_by_label('trn').fill(trn)
    page.get_by_label('day').fill('3')
    page.get_by_label('month').fill('2')
    page.get_by_label('year').fill('1977')
    page.get_by_role('button', name: 'Continue').click
  end

  def then_i_should_be_taken_to_the_review_mentor_details_page
    expect(page).to have_path('/school/register-mentor/review-mentor-details')
  end

  def and_i_should_see_the_mentor_details_in_the_review_page
    expect(page.get_by_text(trn)).to be_visible
    expect(page.get_by_text("Kirk Van Houten")).to be_visible
    expect(page.get_by_text("3 February 1977")).to be_visible
  end

  def when_i_select_that_my_mentor_name_is_incorrect
    page.get_by_label("No, they changed their name or it's spelt wrong").check
  end

  def and_i_enter_the_corrected_name
    page.get_by_label('Enter the correct full name').fill('Kirk Van Damme')
  end

  def and_i_click_confirm_and_continue
    page.get_by_role('button', name: 'Confirm and continue').click
  end

  def then_i_should_be_taken_to_the_email_address_page
    expect(page).to have_path('/school/register-mentor/email-address')
  end

  def when_i_enter_the_mentor_email_address
    page.get_by_label('email').fill('example@example.com')
  end

  def and_i_click_continue
    page.get_by_role('button', name: "Continue").click
  end

  def then_i_should_be_taken_to_mentoring_at_your_school_only_page
    expect(page).to have_path('/school/register-mentor/mentoring-at-new-school-only')
  end

  def when_i_select_yes_they_will_be_mentoring_at_our_school_only
    page.get_by_role(:radio, name: "Yes, they will be mentoring at our school only").check
    page.get_by_role(:button, name: 'Continue').click
  end

  def then_i_should_be_taken_to_mentor_start_date_page
    expect(page).to have_path('/school/register-mentor/started-on')
  end

  def when_i_enter_mentor_start_date
    @mentor_start_date = Date.current
    page.get_by_label('Day').fill(@mentor_start_date.day.to_s)
    page.get_by_label('Month').fill(@mentor_start_date.month.to_s)
    page.get_by_label('Year').fill(@mentor_start_date.year.to_s)
  end

  def then_i_should_be_taken_to_previous_training_period_details_page
    expect(page).to have_path('/school/register-mentor/previous-training-period-details')
  end

  def and_i_should_see_previous_training_period_details
    expect(page.locator('dt', hasText: 'School name')).to be_visible
    expect(page.locator('dd', hasText: @training_period.school_partnership.school.name)).to be_visible
    expect(page.locator('dt', hasText: 'Lead provider')).to be_visible
    expect(page.locator('dd', hasText: @training_period.school_partnership.lead_provider.name)).to be_visible
    expect(page.locator('dt', hasText: 'Delivery partner')).to be_visible
    expect(page.locator('dd', hasText: @training_period.school_partnership.delivery_partner.name)).to be_visible
  end

  def then_i_should_be_taken_to_programme_choices_page
    expect(page).to have_path('/school/register-mentor/programme-choices')
  end

  def when_i_select_yes_use_same_programme_choices
    page.get_by_role(:radio, name: "Yes").check
    page.get_by_role(:button, name: 'Continue').click
  end

  def then_i_should_be_taken_to_the_check_answers_page
    expect(page).to have_path('/school/register-mentor/check-answers')
  end

  def and_i_should_see_all_the_mentor_data_on_the_page
    expect(page.locator('dt', hasText: 'Teacher reference number (TRN)')).to be_visible
    expect(page.locator('dd', hasText: trn)).to be_visible
    expect(page.locator('dt', hasText: 'Name')).to be_visible
    expect(page.locator('dd', hasText: 'Kirk Van Damme')).to be_visible
    expect(page.locator('dt', hasText: 'Email address')).to be_visible
    expect(page.locator('dd', hasText: 'example@example.com')).to be_visible
    expect(page.locator('dt', hasText: 'Mentoring only at your school')).to be_visible
    expect(page.locator('dd', hasText: 'Yes')).to be_visible
    expect(page.locator('dt', hasText: 'Mentor start date')).to be_visible
    expect(page.locator('dd', hasText: @mentor_start_date.to_fs(:govuk))).to be_visible
    expect(page.locator('dt', hasText: 'Lead provider')).to be_visible
    expect(page.locator('dd', hasText: @lead_provider.name)).to be_visible
  end

  def when_i_click_confirm_details
    page.get_by_role('button', name: 'Confirm details').click
  end

  def then_i_should_be_taken_to_the_confirmation_page
    expect(page).to have_path('/school/register-mentor/confirmation')
  end

  def and_mentor_has_mentorship_with_new_school
    expect(@existing_mentor_at_school_period.reload.finished_on).not_to be_nil
    expect(@teacher.mentor_at_school_periods.count).to eq(2)

    new_mentor_at_school_period = @teacher.mentor_at_school_periods.excluding(@existing_mentor_at_school_period).last
    expect(new_mentor_at_school_period.started_on).to eq(@mentor_start_date)
    expect(new_mentor_at_school_period.finished_on).to be_nil
    expect(new_mentor_at_school_period.training_periods.count).to eq(1)
  end
end
