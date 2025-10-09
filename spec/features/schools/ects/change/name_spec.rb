RSpec.describe "Changing an ECT's name", :enable_schools_interface do
  let!(:ect_at_school_period) do
    FactoryBot.create(:ect_at_school_period, :not_started_yet, school:, teacher:)
  end

  let(:teacher) do
    FactoryBot.create(:teacher, trs_first_name: 'Miriam', trs_last_name: 'Margolyes')
  end

  let(:school) { FactoryBot.create(:school) }

  before do
    given_i_am_logged_in_as_a_school_user
    then_i_should_be_taken_to_the_ects_page
    when_i_select_an_ect
    and_i_try_to_change_the_ect_name
    then_i_should_see_the_change_name_page
  end

  scenario 'valid name' do
    when_i_change_the_name_to('Sister Mildred')
    and_i_click_the_continue_button
    then_i_should_be_taken_to_the_check_answers_page
    and_i_should_see_the_name('Sister Mildred')
    and_i_should_see_the_name('Miriam Margolyes')
    and_i_click_the_confirmation_button
    then_i_should_be_taken_to_the_confirmation_page
    then_the_teacher_name_should_be_corrected
  end

  scenario 'edit before confirming' do
    when_i_change_the_name_to('Professor Sprout')
    and_i_click_the_continue_button
    then_i_should_be_taken_to_the_check_answers_page
    and_i_click_the_back_link
    then_i_should_see_the_change_name_page
    and_the_name_field_should_be('Professor Sprout')
    when_i_change_the_name_to('Sister Mildred')
    and_i_click_the_continue_button
    and_i_click_the_confirmation_button
    then_the_teacher_name_should_be_corrected
  end

  scenario 'cancel and reset' do
    when_i_change_the_name_to('Professor Sprout')
    and_i_click_the_continue_button
    then_i_should_be_taken_to_the_check_answers_page
    and_i_click_the_cancel_link
    and_i_try_to_change_the_ect_name
    then_i_should_see_the_change_name_page
    then_the_form_should_be_reset
  end

  scenario 'invalid long name' do
    when_i_change_the_name_to(Faker::Lorem.characters(number: 71))
    and_i_click_the_continue_button
    expect(page.get_by_role('link', name: 'Corrected name must be 70 characters or less')).to be_visible
    then_i_should_be_taken_to_the_edit_page
  end

  scenario 'invalid blank name' do
    when_i_change_the_name_to('')
    and_i_click_the_continue_button
    expect(page.get_by_role('link', name: 'Enter the correct full name')).to be_visible
    then_i_should_be_taken_to_the_edit_page
  end

  scenario 'invalid same name' do
    when_i_change_the_name_to('Miriam Margolyes')
    and_i_click_the_continue_button
    expect(page.get_by_role('link', name: 'The name must be different from the current name')).to be_visible
    then_i_should_be_taken_to_the_edit_page
  end

  def given_i_am_logged_in_as_a_school_user
    sign_in_as_school_user(school:)
  end

  def then_i_should_be_taken_to_the_ects_page
    expect(page).to have_path('/school/home/ects')
  end

  def when_i_select_an_ect
    page.get_by_role('link', name: 'Miriam Margolyes').click
  end

  def then_i_should_see_the_change_name_page
    expect(page.get_by_text('Change name for Miriam Margolyes')).to be_visible
  end

  def when_i_change_the_name_to(name)
    page.get_by_label('What’s the correct full name for Miriam Margolyes?').fill(name)
  end

  def and_i_try_to_change_the_ect_name
    page.get_by_role('link', name: 'Change').first.click
  end

  def and_i_click_the_continue_button
    page.get_by_role('button', name: 'Continue').click
  end

  def and_i_click_the_confirmation_button
    page.get_by_role('button', name: 'Confirm change').click
  end

  def and_i_click_the_back_link
    page.get_by_role('link', name: 'Back', exact: true).click
  end

  def and_i_click_the_cancel_link
    page.get_by_role('link', name: 'Cancel').click
  end

  def then_i_should_be_taken_to_the_edit_page
    expect(page).to have_path("/school/ects/#{ect_at_school_period.id}/change-name/edit")
  end

  def then_i_should_be_taken_to_the_check_answers_page
    expect(page).to have_path("/school/ects/#{ect_at_school_period.id}/change-name/check-answers")
  end

  def then_i_should_be_taken_to_the_confirmation_page
    expect(page).to have_path("/school/ects/#{ect_at_school_period.id}/change-name/confirmation")
  end

  def and_i_should_see_the_name(name)
    expect(page.get_by_text(name, exact: true)).to be_visible
  end

  def then_the_teacher_name_should_be_corrected
    expect(teacher.reload.corrected_name).to eq('Sister Mildred')
  end

  def then_the_form_should_be_reset
    expect(page.locator('#edit-name-field').input_value).to eq('Miriam Margolyes')
  end

  def and_the_name_field_should_be(name)
    expect(page.locator('#edit-name-field').input_value).to eq(name)
  end
end
