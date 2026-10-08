RSpec.describe "Add a mentor to a withdrawn provider led ECT" do
  include_context "safe_schedules"

  let(:overridden_current_date) { mid_year + 1.month }

  before do
    given_there_is_a_school_in_the_service
    and_the_school_has_a_withdrawn_provider_led_ect_with_no_mentor
    and_the_school_has_a_mentor_eligible_to_mentor_the_ect
    and_i_sign_in_as_that_school_user
    when_i_click_to_assign_a_mentor_to_the_ect
    then_i_am_on_the_who_will_mentor_page
  end

  scenario "School chooses a lead provider for the mentor" do
    given_i_select_the_mentor
    and_i_click_continue
    then_i_should_be_taken_to_the_lead_provider_page
    and_the_back_link_links_to_the_who_will_mentor_page

    given_i_choose_the_lead_provider
    and_i_click_continue
    then_i_should_be_taken_to_the_mentorship_confirmation_page
    and_the_mentor_has_a_training_period_with_the_chosen_lead_provider
  end

  def given_there_is_a_school_in_the_service
    @school = FactoryBot.create(:school, urn: "1234567")
  end

  def and_i_sign_in_as_that_school_user
    sign_in_as_school_user(school: @school)
  end

  def and_the_school_has_a_withdrawn_provider_led_ect_with_no_mentor
    contract_period = FactoryBot.create(:contract_period, :with_schedules, :current)

    @lead_provider = FactoryBot.create(:lead_provider, name: "Goku")
    framework_agreement = FactoryBot.create(:framework_agreement, lead_provider: @lead_provider, contract_period:)

    @ect = FactoryBot.create(:ect_at_school_period, :unfinished, school: @school, started_on: mid_year)
    @ect_name = Teachers::Name.new(@ect.teacher).full_name

    FactoryBot.create(
      :training_period,
      :provider_led,
      :with_no_school_partnership,
      ect_at_school_period: @ect,
      expression_of_interest: framework_agreement,
      schedule: contract_period.schedules.find_by!(identifier: "ecf-standard-september"),
      started_on: mid_year,
      finished_on: mid_year + 2.weeks,
      withdrawn_at: mid_year + 2.weeks,
      withdrawal_reason: "other"
    )
  end

  def and_the_school_has_a_mentor_eligible_to_mentor_the_ect
    @mentor = FactoryBot.create(:mentor_at_school_period, :unfinished, school: @school, started_on: mid_year)
    @mentor_name = Teachers::Name.new(@mentor.teacher).full_name
  end

  def when_i_click_to_assign_a_mentor_to_the_ect
    page.get_by_role(:link, name: "Assign a mentor for this ECT").click
  end

  def then_i_am_on_the_who_will_mentor_page
    expect(page.get_by_text("Who will mentor #{@ect_name}?")).to be_visible
    expect(page).to have_path("/school/ects/#{@ect.id}/mentorship/new")
  end

  def given_i_select_the_mentor
    page.get_by_role(:radio, name: @mentor_name).check
  end

  def then_i_should_be_taken_to_the_lead_provider_page
    expect(page).to have_path("/school/assign-existing-mentor/lead-provider")
    expect(page.get_by_text("Which lead provider would you like to contact your school about training #{@mentor_name}?")).to be_visible
  end

  def and_the_back_link_links_to_the_who_will_mentor_page
    expect(page.get_by_role(:link, name: "Back", exact: true).get_attribute("href")).to end_with("/school/ects/#{@ect.id}/mentorship/new?preselect=#{@mentor.id}")
  end

  def given_i_choose_the_lead_provider
    page.get_by_role(:radio, name: @lead_provider.name).check
  end

  def then_i_should_be_taken_to_the_mentorship_confirmation_page
    expect(page).to have_path("/school/assign-existing-mentor/confirmation")
    expect(page.get_by_text("You’ve assigned #{@mentor_name} as a mentor for #{@ect_name}")).to be_visible
  end

  def and_the_mentor_has_a_training_period_with_the_chosen_lead_provider
    training_period = @mentor.reload.training_periods.sole

    expect(training_period).to be_provider_led_training_programme
    expect(training_period.expression_of_interest_lead_provider).to eq(@lead_provider)
  end
end
