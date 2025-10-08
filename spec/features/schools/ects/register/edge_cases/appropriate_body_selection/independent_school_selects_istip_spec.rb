RSpec.describe 'Registering an ECT', :enable_schools_interface do
  include_context 'test trs api client'

  scenario 'Independent school selects ISTIP as appropriate body' do
    given_i_am_logged_in_as_an_independent_school_user
    when_i_start_the_wizard_from_find_ect
    and_i_complete_the_find_ect_step
    and_i_complete_the_review_ect_details_step
    and_i_complete_the_email_address_step
    when_i_enter_a_valid_start_date
    and_i_click_continue
    and_i_select_full_time
    and_i_click_continue
    and_i_select_istip_as_the_appropriate_body
    and_i_select_school_led_as_training_programme
    then_i_am_taken_to_the_check_answers_page

    and_i_see_the_correct_appropriate_body_on_the_page
  end

  def given_i_am_logged_in_as_an_independent_school_user
    school = FactoryBot.create(:school, :independent)
    FactoryBot.create(:appropriate_body, :istip)
    sign_in_as_school_user(school:)
  end

  def when_i_start_the_wizard_from_find_ect
    page.goto('/school/register-ect/find-ect')
  end

  def and_i_complete_the_find_ect_step
    page.get_by_label('trn').fill('9876543')
    page.get_by_label('day').fill('3')
    page.get_by_label('month').fill('2')
    page.get_by_label('year').fill('1977')
    page.get_by_role('button', name: 'Continue').click
  end

  def and_i_complete_the_review_ect_details_step
    # Assume name is correct
    page.get_by_label("Yes").check
    page.get_by_role('button', name: 'Confirm and continue').click
  end

  def and_i_complete_the_email_address_step
    page.fill('input[type="email"]', 'example@example.com')
    page.get_by_role('button', name: 'Continue').click
  end

  def when_i_enter_a_valid_start_date
    page.get_by_label('day').fill(1.month.ago.day.to_s)
    page.get_by_label('month').fill(1.month.ago.month.to_s)
    page.get_by_label('year').fill(1.month.ago.year.to_s)
  end

  def and_i_click_continue
    page.get_by_role('button', name: "Continue").click
  end

  def and_i_select_istip_as_the_appropriate_body
    page.get_by_label('Independent Schools Teacher Induction Panel (ISTIP)').check
    and_i_click_continue
  end

  def and_i_select_school_led_as_training_programme
    page.get_by_label("School-led").check
    and_i_click_continue
  end

  def and_i_select_full_time
    page.get_by_label("Full time").check
  end

  def then_i_am_taken_to_the_check_answers_page
    expect(page).to have_path('/school/register-ect/check-answers')
  end

  def and_i_see_the_correct_appropriate_body_on_the_page
    expect(page.get_by_text('ISTIP')).to be_visible
  end
end
