RSpec.describe 'Registering an ECT' do
  include_context 'fake trs api client'

  let(:trn) { '9876543' }

  before do
    FactoryBot.create(:appropriate_body, name: 'Golden Leaf Teaching Hub')
  end

  scenario 'happy path' do
    given_i_am_logged_in_as_a_state_funded_school_user
    and_i_am_on_the_schools_landing_page
    when_i_start_adding_an_ect
    then_i_am_in_the_requirements_page

    when_i_click_continue
    then_i_am_on_the_find_ect_step_page

    when_i_submit_the_find_ect_form(trn:, dob_day: '3', dob_month: '2', dob_year: '1977')
    then_i_should_be_taken_to_the_review_ect_details_page
    and_i_should_see_the_ect_details_in_the_review_page

    when_i_select_that_my_ect_name_is_incorrect
    and_i_enter_the_corrected_name
    and_i_click_confirm_and_continue
    then_i_should_be_taken_to_the_email_address_page

    when_i_enter_the_ect_email_address
    and_i_click_continue
    then_i_should_be_taken_to_the_ect_start_date_page

    when_i_enter_a_valid_start_date
    and_i_click_continue
    then_i_should_i_should_be_taken_to_the_working_pattern_page

    when_i_select_full_time
    and_i_click_continue
    then_i_should_be_taken_to_the_appropriate_bodies_page

    when_i_select_an_appropriate_body
    and_i_click_continue
    then_i_should_be_taken_to_the_programme_type_page

    when_i_select_school_led
    and_i_click_continue

    then_i_should_be_taken_to_the_check_answers_page
    and_i_should_see_all_the_ect_data_on_the_page

    when_i_try_to_change_the_name
    then_i_should_be_taken_to_the_change_name_page
    when_i_click_the_back_link
    then_i_should_be_taken_to_the_check_answers_page

    when_i_try_to_change_the_email_address
    then_i_should_be_taken_to_the_change_email_address_page

    when_i_enter_a_new_ect_email_address
    and_i_click_continue
    then_i_should_be_taken_to_the_check_answers_page
    and_i_should_see_the_new_email

    when_i_click_confirm_details
    then_i_should_be_taken_to_the_confirmation_page

    when_i_click_on_back_to_your_ects
    then_i_should_be_taken_to_the_ects_page
    and_i_should_see_the_ect_i_registered
  end

  def given_i_am_logged_in_as_a_state_funded_school_user
    school = FactoryBot.create(:school, gias_school: FactoryBot.create(:gias_school, :state_school_type))
    sign_in_as_school_user(school:)
  end

  def and_i_am_on_the_schools_landing_page
    path = '/schools/home/ects'
    page.goto path
    expect(page.url).to end_with(path)
  end

  def when_i_start_adding_an_ect
    page.get_by_role('link', name: 'Add an ECT').click
  end

  def then_i_am_in_the_requirements_page
    expect(page.url).to end_with('/schools/register-ect/what-you-will-need')
  end

  def when_i_click_continue
    page.get_by_role('link', name: 'Continue').click
  end

  def then_i_am_on_the_find_ect_step_page
    expect(page.url).to end_with('/schools/register-ect/find-ect')
  end

  def when_i_submit_the_find_ect_form(trn:, dob_day:, dob_month:, dob_year:)
    page.get_by_label('trn').fill(trn)
    page.get_by_label('day').fill(dob_day)
    page.get_by_label('month').fill(dob_month)
    page.get_by_label('year').fill(dob_year)
    page.get_by_role('button', name: 'Continue').click
  end

  def then_i_should_be_taken_to_the_review_ect_details_page
    expect(page.url).to end_with('/schools/register-ect/review-ect-details')
  end

  def and_i_should_see_the_ect_details_in_the_review_page
    expect(page.get_by_text(trn)).to be_visible
    expect(page.get_by_text("Kirk Van Houten")).to be_visible
    expect(page.get_by_text("3 February 1977")).to be_visible
  end

  def when_i_select_that_my_ect_name_is_incorrect
    page.get_by_label("No, they changed their name or it's spelt wrong").check
  end

  def and_i_enter_the_corrected_name
    page.get_by_label('Enter the correct full name').fill('Kirk Van Damme')
  end

  def and_i_click_confirm_and_continue
    page.get_by_role('button', name: 'Confirm and continue').click
  end

  def then_i_should_be_taken_to_the_email_address_page
    expect(page.url).to end_with('/schools/register-ect/email-address')
  end

  def when_i_enter_the_ect_email_address
    page.fill('#email-address-email-field', 'example@example.com')
  end

  def then_i_should_be_taken_to_the_programme_type_page
    expect(page.url).to end_with('/schools/register-ect/programme-type')
  end

  def when_i_select_school_led
    page.get_by_label("School-led").check
  end

  def when_i_select_full_time
    page.get_by_label("Full time").check
  end

  def and_i_click_continue
    page.get_by_role('button', name: "Continue").click
  end

  def then_i_should_be_taken_to_the_ect_start_date_page
    expect(page.url).to end_with('/schools/register-ect/start-date')
  end

  def when_i_enter_a_valid_start_date
    page.get_by_label('month').fill(one_month_ago_today.month.to_s)
    page.get_by_label('year').fill(one_month_ago_today.year.to_s)
  end

  def then_i_should_be_taken_to_the_appropriate_bodies_page
    expect(page.url).to end_with('/schools/register-ect/state-school-appropriate-body')
  end

  def when_i_select_an_appropriate_body
    page.get_by_role('combobox', name: "Enter appropriate body name")
        .first
        .select_option(value: "Golden Leaf Teaching Hub")
  end

  def then_i_should_i_should_be_taken_to_the_working_pattern_page
    expect(page.url).to end_with('/schools/register-ect/working-pattern')
  end

  def then_i_should_be_taken_to_the_check_answers_page
    expect(page.url).to end_with('/schools/register-ect/check-answers')
  end

  def and_i_should_see_all_the_ect_data_on_the_page
    expect(page.get_by_text(trn)).to be_visible
    expect(page.get_by_text("Kirk Van Damme")).to be_visible
    expect(page.get_by_text('example@example.com')).to be_visible
    expect(page.get_by_text("#{Date::MONTHNAMES[one_month_ago_today.month]} #{one_month_ago_today.year}")).to be_visible
    expect(page.get_by_text('Golden Leaf Teaching Hub')).to be_visible
  end

  def when_i_try_to_change_the_name
    click_change_link_for_field("Name")
  end

  def then_i_should_be_taken_to_the_change_name_page
    expect(page.url).to end_with('/schools/register-ect/change-review-ect-details')
  end

  def when_i_click_the_back_link
    page.get_by_role('link', name: 'Back', exact: true).click
  end

  def when_i_try_to_change_the_email_address
    click_change_link_for_field("Email address")
  end

  def then_i_should_be_taken_to_the_change_email_address_page
    expect(page.url).to end_with('/schools/register-ect/change-email-address')
  end

  def when_i_enter_a_new_ect_email_address
    page.fill('#change-email-address-email-field', 'new@example.com')
  end

  def and_i_should_see_the_new_email
    expect(page.get_by_text('new@example.com')).to be_visible
  end

  def when_i_click_confirm_details
    page.get_by_role('button', name: 'Confirm details').click
  end

  def and_i_should_see_the_ect_i_registered
    expect(page.get_by_role('link', name: 'Kirk Van Damme')).to be_visible
  end

  def then_i_should_be_taken_to_the_confirmation_page
    expect(page.url).to end_with('/schools/register-ect/confirmation')
  end

  def when_i_click_on_back_to_your_ects
    page.get_by_role('link', name: 'Back to your ECTs').click
  end

  def then_i_should_be_taken_to_the_ects_page
    expect(page.url).to end_with('/schools/home/ects')
  end

  def one_month_ago_today
    @one_month_ago_today ||= Time.zone.today.prev_month
  end

  def click_change_link_for_field(key)
    row = page.locator("div.govuk-summary-list__row", hasText: key)
    row.locator("a.govuk-link", hasText: "Change").click
  end
end
