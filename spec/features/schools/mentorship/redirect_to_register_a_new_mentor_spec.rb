RSpec.describe 'Redirect to register a new mentor for an ECT', :enable_schools_interface do
  include_context 'test trs api client'
  include SchoolPartnershipHelpers

  before do
    allow(Rails.application.config).to receive_messages(enable_test_guidance: false)
  end

  let(:trn) { '9876543' }

  scenario 'happy path' do
    given_there_is_a_school_in_the_service
    and_the_school_is_in_a_partnership_with_a_lead_provider
    and_there_is_an_ect_with_no_mentor_registered_at_the_school
    and_there_is_a_mentor_registered_at_the_school_eligible_to_mentor_the_ect
    and_i_sign_in_as_that_school_user
    and_i_am_on_the_schools_landing_page
    when_i_click_to_assign_a_mentor_to_the_ect
    then_i_am_in_the_who_will_mentor_page

    when_i_select_register_a_new_mentor
    then_i_am_in_the_requirements_page

    when_i_click_continue
    then_i_should_be_taken_to_the_find_mentor_page

    when_i_submit_the_find_mentor_form(trn:, dob_day: '3', dob_month: '2', dob_year: '1977')
    then_i_should_be_taken_to_the_review_mentor_details_page
    and_i_should_see_the_mentor_details_in_the_review_page

    when_i_answer_yes_the_details_of_the_mentor_are_correct
    and_i_click_confirm_and_continue
    then_i_should_be_taken_to_the_email_address_page

    when_i_enter_the_mentor_email_address
    and_i_click_continue
    then_i_should_be_taken_to_the_review_mentor_eligibility_page
    and_i_should_see_mentor_funding_on_the_page
    and_i_click_continue
    then_i_should_be_taken_to_the_check_answers_page
    and_i_should_see_all_the_mentor_data_on_the_page

    when_i_click_confirm_details
    then_i_should_be_taken_to_the_confirmation_page

    when_i_click_on_back_to_ects
    then_i_should_be_taken_to_the_ects_page
    and_the_ect_is_shown_linked_to_the_mentor_just_registered
  end

  def given_there_is_a_school_in_the_service
    @school = FactoryBot.create(:school, urn: "1234567")
  end

  def and_the_school_is_in_a_partnership_with_a_lead_provider
    @contract_period = FactoryBot.create(:contract_period, :with_schedules, :current)
    @school_partnership = make_partnership_for(@school, @contract_period)
  end

  def and_i_sign_in_as_that_school_user
    sign_in_as_school_user(school: @school)
  end

  def and_there_is_an_ect_with_no_mentor_registered_at_the_school
    @ect = FactoryBot.create(:ect_at_school_period, :with_training_period, :ongoing, lead_provider: @lead_provider, school: @school)
    @ect_name = Teachers::Name.new(@ect.teacher).full_name

    FactoryBot.create(:training_period, :ongoing, school_partnership: @school_partnership, ect_at_school_period: @ect)
  end

  def and_there_is_a_mentor_registered_at_the_school_eligible_to_mentor_the_ect
    @mentor = FactoryBot.create(:mentor_at_school_period, :ongoing, school: @school)
    @mentor_name = Teachers::Name.new(@mentor.teacher).full_name
  end

  def and_i_am_on_the_schools_landing_page
    path = '/school/home/ects'
    page.goto path
    expect(page).to have_path(path)
  end

  def when_i_click_to_assign_a_mentor_to_the_ect
    page.get_by_role('link', name: 'Assign a mentor for this ECT').click
  end

  def then_i_am_in_the_who_will_mentor_page
    expect(page.get_by_text("Who will mentor #{@ect_name}?")).to be_visible
    expect(page).to have_path("/school/ects/#{@ect.id}/mentorship/new")
  end

  def when_i_select_register_a_new_mentor
    page.get_by_role(:radio, name: "Register a new mentor").check
    page.get_by_role(:button, name: 'Continue').click
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

  def when_i_submit_the_find_mentor_form(trn:, dob_day:, dob_month:, dob_year:)
    page.get_by_label('trn').fill(trn)
    page.get_by_label('day').fill(dob_day)
    page.get_by_label('month').fill(dob_month)
    page.get_by_label('year').fill(dob_year)
    page.get_by_role('button', name: 'Continue').click
  end

  def then_i_should_be_taken_to_the_review_mentor_eligibility_page
    expect(page).to have_path('/school/register-mentor/review-mentor-eligibility')
  end

  def and_i_should_see_mentor_funding_on_the_page
    expect(page.get_by_text("Our records show that Kirk Van Houten can get up to 20 hours of ECTE mentor training as your school is working with a DfE-funded training provider.")).to be_visible
    expect(page.get_by_text("We'll pass on their details to Xavier's School for Gifted Youngsters who will contact them to arrange the training.")).to be_visible
  end

  def then_i_should_be_taken_to_the_review_mentor_details_page
    expect(page).to have_path('/school/register-mentor/review-mentor-details')
  end

  def and_i_should_see_the_mentor_details_in_the_review_page
    expect(page.get_by_text(trn)).to be_visible
    expect(page.get_by_text("Kirk Van Houten")).to be_visible
    expect(page.get_by_text("3 February 1977")).to be_visible
  end

  def when_i_answer_yes_the_details_of_the_mentor_are_correct
    page.get_by_role(:radio, name: "Yes").check
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

  def then_i_should_be_taken_to_the_check_answers_page
    expect(page).to have_path('/school/register-mentor/check-answers')
  end

  def and_i_should_see_all_the_mentor_data_on_the_page
    expect(page.locator('dt', hasText: 'Teacher reference number (TRN)')).to be_visible
    expect(page.locator('dd', hasText: trn)).to be_visible
    expect(page.locator('dt', hasText: 'Name')).to be_visible
    expect(page.locator('dd', hasText: 'Kirk Van Houten')).to be_visible
    expect(page.locator('dt', hasText: 'Email address')).to be_visible
    expect(page.locator('dd', hasText: 'example@example.com')).to be_visible
    expect(page.locator('dt', hasText: 'Lead provider')).to be_visible
    expect(page.locator('dd', hasText: "Xavier's School for Gifted Youngsters")).to be_visible
  end

  def when_i_click_confirm_details
    page.get_by_role('button', name: 'Confirm details').click
  end

  def then_i_should_be_taken_to_the_confirmation_page
    expect(page).to have_path('/school/register-mentor/confirmation')
  end

  def when_i_click_on_back_to_ects
    page.get_by_role('link', name: 'Back to ECTs').click
  end

  def then_i_should_be_taken_to_the_ects_page
    expect(page).to have_path('/school/home/ects')
  end

  def and_the_ect_is_shown_linked_to_the_mentor_just_registered
    expect(page.get_by_role(:link, name: @ect_name)).to be_visible
    expect(page.locator('dt', hasText: 'Mentor')).to be_visible
    expect(page.locator('dd', hasText: 'Kirk Van Houten')).to be_visible
  end
end
