RSpec.describe 'Selecting a different lead provider', :enable_schools_interface do
  include_context 'test trs api client'
  include SchoolPartnershipHelpers

  scenario 'Registering a new mentor' do
    given_there_is_a_school_in_the_service
    and_the_school_is_in_a_partnership_with_a_lead_provider
    and_there_is_an_ect_with_no_mentor_registered_at_the_school
    and_i_sign_in_as_that_school_user
    and_i_click_to_assign_a_mentor_to_the_ect
    and_i_click_continue('link')
    and_i_submit_the_find_mentor_form
    and_i_choose_that_the_details_are_correct
    and_i_click_confirm_and_continue
    then_i_should_be_taken_to_the_email_address_page

    when_i_enter_the_mentor_email_address
    and_i_click_continue('button')
    then_i_should_be_taken_to_the_review_mentor_eligibility_page

    when_i_click_choose_another_provider_link
    then_i_should_be_taken_to_eligibility_lead_provider_page

    when_i_select_a_different_lead_provider
    then_i_should_be_taken_to_the_check_answers_page
    and_i_should_see_all_the_mentor_data_on_the_page
    and_the_back_link_points_to_the_eligibility_lead_provider_page

    when_i_click_confirm_details
    then_i_should_be_taken_to_the_confirmation_page
  end

  def and_the_school_is_in_a_partnership_with_a_lead_provider
    @contract_period = FactoryBot.create(:contract_period, :with_schedules, :current)
    @school_partnership = make_partnership_for(@school, @contract_period)
    @lead_provider = @school_partnership.lead_provider_delivery_partnership.lead_provider
  end

  def and_the_back_link_points_to_the_eligibility_lead_provider_page
    expect(page.get_by_role('link', name: 'Back', exact: true).get_attribute('href')).to end_with('/school/register-mentor/eligibility-lead-provider')
  end

  def and_i_choose_that_the_details_are_correct
    page.get_by_label('Yes').check
  end

  def given_there_is_a_school_in_the_service
    @school = FactoryBot.create(:school, urn: "1234567")
  end

  def and_i_sign_in_as_that_school_user
    sign_in_as_school_user(school: @school)
  end

  def and_there_is_an_ect_with_no_mentor_registered_at_the_school
    contract_period = FactoryBot.create(:contract_period, year: Date.current.year)

    @another_lead_provider = FactoryBot.create(:lead_provider, name: "Another lead provider")
    FactoryBot.create(:active_lead_provider, lead_provider: @another_lead_provider, contract_period:)

    @ect = FactoryBot.create(:ect_at_school_period, :ongoing, school: @school)
    @training_period = FactoryBot.create(:training_period, :ongoing, :provider_led, ect_at_school_period: @ect, school_partnership: @school_partnership)
    @ect_name = Teachers::Name.new(@ect.teacher).full_name
  end

  def and_i_click_to_assign_a_mentor_to_the_ect
    page.get_by_role('link', name: 'Assign a mentor for this ECT').click
  end

  def and_i_click_continue(link_or_button)
    page.get_by_role(link_or_button, name: 'Continue').click
  end

  def and_i_submit_the_find_mentor_form
    page.get_by_label('Teacher reference number (TRN)').fill(trn)
    page.get_by_label('day').fill('3')
    page.get_by_label('month').fill('2')
    page.get_by_label('year').fill('1977')
    page.get_by_role('button', name: 'Continue').click
  end

  def then_i_should_be_taken_to_the_review_mentor_details_page
    expect(page).to have_path('/school/register-mentor/review-mentor-details')
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

  def then_i_should_be_taken_to_the_review_mentor_eligibility_page
    expect(page).to have_path('/school/register-mentor/review-mentor-eligibility')
  end

  def when_i_click_choose_another_provider_link
    page.get_by_role('link', name: "#{@lead_provider.name} will not be providing mentor training to Kirk Van Houten").click
  end

  def then_i_should_be_taken_to_eligibility_lead_provider_page
    expect(page).to have_path('/school/register-mentor/eligibility-lead-provider')
  end

  def when_i_select_a_different_lead_provider
    page.get_by_role(:radio, name: @another_lead_provider.name).check
    page.get_by_role(:button, name: 'Continue').click
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
    expect(page.locator('dd', hasText: @another_lead_provider.name)).to be_visible
  end

  def when_i_click_confirm_details
    page.get_by_role('button', name: 'Confirm details').click
  end

  def then_i_should_be_taken_to_the_confirmation_page
    expect(page).to have_path('/school/register-mentor/confirmation')
  end

  def trn
    '3002586'
  end
end
