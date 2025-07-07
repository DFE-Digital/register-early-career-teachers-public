RSpec.describe 'Registering an ECT' do
  include_context 'fake trs api client'

  scenario 'previously registered' do
    given_i_am_logged_in_as_a_state_funded_school_user_who_has_previously_registered_an_ect
    and_i_am_on_the_schools_ects_index_page
    and_i_start_adding_an_ect
    and_i_click_continue
    and_i_submit_the_find_ect_form
    and_i_choose_that_the_details_are_correct
    and_i_click_confirm_and_continue
    then_i_am_on_the_registered_before_page
    and_i_click_the_continue_button
    then_i_am_on_the_email_address_page

    when_i_click_back
    then_i_am_on_the_registered_before_page

    when_i_click_back
    then_i_am_on_the_review_ect_details_page
  end

  def then_i_am_on_the_registered_before_page
    expect(page.url).to end_with('/schools/register-ect/registered-before')
  end

  def given_i_am_logged_in_as_a_state_funded_school_user_who_has_previously_registered_an_ect
    @teacher = create(:teacher)
    school = create(:school)

    ect_at_school_period =
      create(
        :ect_at_school_period,
        school:,
        teacher: @teacher,
        started_on: Date.new(2023, 9, 1),
        finished_on: Date.new(2024, 7, 31)
      )

    create(
      :training_period,
      ect_at_school_period:,
      started_on: Date.new(2023, 9, 1),
      finished_on: Date.new(2024, 7, 31)
    )

    create(:induction_period, teacher: @teacher, started_on: Date.new(2023, 9, 1))

    sign_in_as_school_user(school:)
  end

  def and_i_am_on_the_schools_ects_index_page
    page.goto '/schools/home/ects'
  end

  def and_i_start_adding_an_ect
    page.get_by_role('link', name: 'Register an ECT starting at your school').click
  end

  def and_i_click_continue
    page.get_by_role('link', name: 'Continue').click
  end

  def when_i_click_back
    page.get_by_role('link', name: 'Back', exact: true).click
  end

  def and_i_click_the_continue_button
    page.get_by_role('button', name: 'Continue').click
  end

  def and_i_submit_the_find_ect_form
    page.get_by_label('Teacher reference number (TRN)').fill(@teacher.trn)
    page.get_by_label('day').fill('3')
    page.get_by_label('month').fill('2')
    page.get_by_label('year').fill('1977')
    page.get_by_role('button', name: 'Continue').click
  end

  def and_i_choose_that_the_details_are_correct
    page.get_by_label('Yes').check
  end

  def and_i_click_confirm_and_continue
    page.get_by_role('button', name: 'Confirm and continue').click
  end

  def then_i_am_on_the_email_address_page
    expect(page.url).to end_with('/schools/register-ect/email-address')
  end

  def then_i_am_on_the_review_ect_details_page
    expect(page.url).to end_with('/schools/register-ect/review-ect-details')
  end
end
