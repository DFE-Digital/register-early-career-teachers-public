RSpec.describe 'Registering an ECT' do
  before do
    create(:appropriate_body, name: 'Golden Leaf Teaching Hub')
  end

  scenario 'Independent school selects ISTIP as appropriate body' do
    given_i_am_logged_in_as_an_independent_school_user
    and_i_am_on_the_start_date_step_of_the_register_ect_journey

    when_i_enter_a_valid_start_date
    and_i_click_continue
    and_i_select_full_time
    and_i_click_continue
    and_i_select_a_teaching_school_hub_as_the_appropriate_body_type
    and_i_select_an_appropriate_body
    and_i_click_continue
    then_i_am_taken_to_the_training_programme_page

    when_i_select_school_led
    and_i_click_continue
    then_i_am_taken_to_the_check_answers_page
    and_i_see_the_correct_appropriate_body_on_the_page
  end

  def and_i_am_on_the_start_date_step_of_the_register_ect_journey
    page.goto('/schools/register-ect/start-date')
  end

  def given_i_am_logged_in_as_an_independent_school_user
    school = create(:school, :independent)
    sign_in_as_school_user(school:)
  end

  def then_i_am_in_the_requirements_page
    expect(page.url).to end_with('/schools/register-ect/what-you-will-need')
  end

  def and_i_click_continue
    page.get_by_role('button', name: "Continue").click
  end

  def then_i_should_be_taken_to_the_ect_start_date_page
    expect(page.url).to end_with('/schools/register-ect/start-date')
  end

  def when_i_enter_a_valid_start_date
    page.get_by_label('day').fill(1.month.ago.day.to_s)
    page.get_by_label('month').fill(1.month.ago.month.to_s)
    page.get_by_label('year').fill(1.month.ago.year.to_s)
  end

  def and_i_select_a_teaching_school_hub_as_the_appropriate_body_type
    page.get_by_label('A different appropriate body').check
  end

  def and_i_select_an_appropriate_body
    page.get_by_role('combobox', name: "")
        .first
        .select_option(value: "Golden Leaf Teaching Hub")
  end

  def then_i_am_taken_to_the_training_programme_page
    expect(page.url).to end_with('/schools/register-ect/training-programme')
  end

  def when_i_select_school_led
    page.get_by_label("School-led").check
  end

  def and_i_select_full_time
    page.get_by_label("Full time").check
  end

  def then_i_am_taken_to_the_check_answers_page
    expect(page.url).to end_with('/schools/register-ect/check-answers')
  end

  def and_i_see_the_correct_appropriate_body_on_the_page
    expect(page.get_by_text('Golden Leaf Teaching Hub')).to be_visible
  end
end
