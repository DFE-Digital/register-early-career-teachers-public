RSpec.describe "Admin school management" do
  include UserHelper

  scenario "viewing individual school details with teachers" do
    given_i_am_logged_in_as_an_admin
    and_schools_with_teachers_exist

    when_i_visit_the_schools_page
    then_i_should_see_the_schools_list

    when_i_click_on_a_school
    then_i_should_see_the_school_details_page
    and_i_should_see_the_school_information
    and_i_should_see_the_navigation_sections

    when_i_view_the_overview_section
    then_i_should_see_the_school_overview_details

    when_i_view_the_teachers_section
    then_i_should_see_the_teachers_table
    and_i_should_see_teacher_information

    when_i_click_on_a_teacher_link
    then_i_should_navigate_to_the_teacher_details_page
  end

  scenario "viewing school with no teachers" do
    given_i_am_logged_in_as_an_admin
    and_a_school_with_no_teachers_exists

    when_i_visit_the_school_directly
    then_i_should_see_the_school_details_page

    when_i_view_the_teachers_section
    then_i_should_see_no_teachers_message
  end

private

  def given_i_am_logged_in_as_an_admin
    sign_in_as_dfe_user(role: :admin)
  end

  def and_schools_with_teachers_exist
    @school = FactoryBot.create(:school, urn: '123456', induction_tutor_name: 'Jane Smith', induction_tutor_email: 'jane@school.edu')

    # Create teachers with different roles
    @ect_teacher = FactoryBot.create(:teacher, trs_first_name: 'Alice', trs_last_name: 'Johnson', trn: '1234567')
    @mentor_teacher = FactoryBot.create(:teacher, trs_first_name: 'Bob', trs_last_name: 'Wilson', trn: '7654321')
    @both_roles_teacher = FactoryBot.create(:teacher, trs_first_name: 'Carol', trs_last_name: 'Davis', trn: '1111111')

    # Create periods to establish relationships
    FactoryBot.create(:ect_at_school_period, :ongoing, school: @school, teacher: @ect_teacher)
    FactoryBot.create(:mentor_at_school_period, :ongoing, school: @school, teacher: @mentor_teacher)
    FactoryBot.create(:ect_at_school_period, :ongoing, school: @school, teacher: @both_roles_teacher)
    FactoryBot.create(:mentor_at_school_period, :ongoing, school: @school, teacher: @both_roles_teacher)
  end

  def and_a_school_with_no_teachers_exists
    @empty_school = FactoryBot.create(:school, urn: '999999')
  end

  def when_i_visit_the_schools_page
    page.goto(admin_schools_path)
  end

  def then_i_should_see_the_schools_list
    expect(page.locator('h1').get_by_text("Schools")).to be_visible
    expect(page.get_by_text("Search by name or URN")).to be_visible
  end

  def when_i_click_on_a_school
    page.get_by_role('link', name: @school.name).click
  end

  def when_i_visit_the_school_directly
    page.goto(admin_school_path(@empty_school.urn))
  end

  def then_i_should_see_the_school_details_page
    school_name = @school&.name || @empty_school.name
    school_urn = @school&.urn || @empty_school.urn

    expect(page.get_by_text("URN: #{school_urn}")).to be_visible
    expect(page.locator('h1.govuk-heading-xl').get_by_text(school_name)).to be_visible
  end

  def and_i_should_see_the_school_information
    expect(page.locator('.govuk-breadcrumbs').get_by_role('link', name: 'Schools')).to be_visible
  end

  def and_i_should_see_the_navigation_sections
    expect(page.locator('.govuk-tabs')).to be_visible
    expect(page.locator('.govuk-tabs__list')).to be_visible
    expect(page.locator('.govuk-tabs__list').get_by_text('Overview')).to be_visible
    expect(page.locator('.govuk-tabs__list').get_by_text('Teachers')).to be_visible
    expect(page.locator('.govuk-tabs__list').get_by_text('Partnerships')).to be_visible
  end

  def when_i_view_the_overview_section
    page.locator('.govuk-tabs__list').get_by_text('Overview').click
  end

  def then_i_should_see_the_school_overview_details
    # Check the summary list contains the expected data
    summary_list = page.locator('.govuk-summary-list')
    expect(summary_list.get_by_text("Induction tutor", exact: true)).to be_visible
    expect(summary_list.get_by_text("Jane Smith")).to be_visible
    expect(summary_list.get_by_text("jane@school.edu")).to be_visible
    expect(summary_list.get_by_text("Local authority")).to be_visible
    expect(summary_list.get_by_text("Address")).to be_visible
  end

  def when_i_view_the_teachers_section
    page.locator('.govuk-tabs__list').get_by_text('Teachers').click
  end

  def then_i_should_see_the_teachers_table
    table = page.locator('table.govuk-table')
    expect(table.get_by_text("Name")).to be_visible
    expect(table.get_by_text("TRN")).to be_visible
    expect(table.get_by_text("Type")).to be_visible
    expect(table.get_by_text("Contract period")).to be_visible
  end

  def and_i_should_see_teacher_information
    table = page.locator('table.govuk-table')

    # Check ECT teacher
    expect(table.get_by_text("Alice Johnson")).to be_visible
    expect(table.get_by_text("1234567")).to be_visible
    expect(table.get_by_text("ECT", exact: true)).to be_visible

    # Check mentor teacher
    expect(table.get_by_text("Bob Wilson")).to be_visible
    expect(table.get_by_text("7654321")).to be_visible
    expect(table.get_by_text("Mentor", exact: true)).to be_visible

    # Check teacher with both roles
    expect(table.get_by_text("Carol Davis")).to be_visible
    expect(table.get_by_text("1111111")).to be_visible
    expect(table.get_by_text("ECT & Mentor")).to be_visible

    # Check contract period display (at least one should exist)
    expect(table.get_by_text(Date.current.year.to_s).first).to be_visible
  end

  def when_i_click_on_a_teacher_link
    page.get_by_role('link', name: 'Alice Johnson').click
  end

  def then_i_should_navigate_to_the_teacher_details_page
    expect(page.url).to include(admin_teacher_path(@ect_teacher))
  end

  def then_i_should_see_no_teachers_message
    expect(page.get_by_text("No teachers found at this school.")).to be_visible
    expect(page.locator('table.govuk-table')).not_to be_visible
  end
end
