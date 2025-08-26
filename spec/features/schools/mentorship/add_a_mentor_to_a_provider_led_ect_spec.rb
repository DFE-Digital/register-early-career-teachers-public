RSpec.describe 'Add a mentor to a provider led ECT' do
  before do
    given_there_is_a_school_in_the_service
    and_the_school_has_a_provider_led_ect_with_no_mentor
    and_the_school_has_a_mentor_eligible_to_mentor_the_ect
    and_i_sign_in_as_that_school_user
    when_i_click_to_assign_a_mentor_to_the_ect
    then_i_am_on_the_who_will_mentor_page
  end

  scenario 'Same lead provider' do
    given_i_select_the_mentor
    and_i_click_continue
    then_i_should_be_taken_to_the_eligibility_page

    given_i_click_the_back_link
    and_i_am_back_on_the_who_will_mentor_page
    then_the_mentor_i_previously_selected_is_still_selected

    given_i_click_continue
    and_i_click_continue
    then_i_should_be_taken_to_the_mentorship_confirmation_page

    given_i_click_on_back_to_your_ects
    then_i_should_be_taken_to_the_ects_page
    and_the_ect_is_shown_linked_to_the_mentor_just_registered
  end

  scenario 'New lead provider' do
    given_i_select_the_mentor
    and_i_click_continue
    then_i_should_be_taken_to_the_eligibility_page

    given_i_click_the_back_link
    and_i_am_back_on_the_who_will_mentor_page
    then_the_mentor_i_previously_selected_is_still_selected

    given_i_click_continue
    and_i_click_on_the_my_lead_provider_is_not_providing_mentor_training_link
    and_the_back_link_links_to_the_eligibility_page
    and_i_choose_the_lead_provider_vegeta
    and_i_click_continue
    then_i_should_be_taken_to_the_mentorship_confirmation_page

    given_i_click_on_back_to_your_ects
    then_i_should_be_taken_to_the_ects_page
    and_the_ect_is_shown_linked_to_the_mentor_just_registered
  end

  def and_the_back_link_links_to_the_who_will_mentor_page
    expect(page.get_by_role(:link, name: 'Back').get_attribute('href')).to end_with("/school/ects/#{@ect.id}/mentorship/new")
  end

  def and_the_back_link_links_to_the_eligibility_page
    expect(page.get_by_role(:link, name: 'Back').get_attribute('href')).to end_with("/school/assign-existing-mentor/review-mentor-eligibility")
  end

  def and_i_choose_the_lead_provider_vegeta
    page.get_by_role(:radio, name: @lead_provider_2.name).check
  end

  def and_i_click_on_the_my_lead_provider_is_not_providing_mentor_training_link
    page.get_by_role('link', name: "#{@lead_provider.name} will not be providing mentor training to #{@mentor_name}").click
  end

  def given_there_is_a_school_in_the_service
    @school = FactoryBot.create(:school, urn: "1234567")
  end

  def and_i_sign_in_as_that_school_user
    sign_in_as_school_user(school: @school)
  end

  def and_the_school_has_a_provider_led_ect_with_no_mentor
    @cp_2023 = FactoryBot.create(:contract_period, year: 2023)

    @lead_provider = FactoryBot.create(:lead_provider, name: "Goku")
    @lead_provider_2 = FactoryBot.create(:lead_provider, name: "Vegeta")

    FactoryBot.create(:active_lead_provider, lead_provider: @lead_provider,   contract_period: @cp_2023)
    FactoryBot.create(:active_lead_provider, lead_provider: @lead_provider_2, contract_period: @cp_2023)

    @ect = FactoryBot.create(
      :ect_at_school_period,
      :provider_led,
      :ongoing,
      :with_training_period,
      school: @school,
      started_on: Date.new(2023, 9, 1),
      lead_provider: @lead_provider,
      contract_period: @cp_2023
    )

    @ect_name = Teachers::Name.new(@ect.teacher).full_name
  end

  def and_the_school_has_a_mentor_eligible_to_mentor_the_ect
    @mentor = FactoryBot.create(
      :mentor_at_school_period,
      :ongoing,
      school: @school,
      started_on: Date.new(2023, 9, 1)
    )

    @mentor_name = Teachers::Name.new(@mentor.teacher).full_name
  end

  def when_i_click_to_assign_a_mentor_to_the_ect
    page.get_by_role(:link, name: 'assign a mentor or register a new one').click
  end

  def then_i_am_on_the_who_will_mentor_page
    expect(page.get_by_text("Who will mentor #{@ect_name}?")).to be_visible
    expect(page.url).to end_with("/school/ects/#{@ect.id}/mentorship/new")
  end

  def and_i_am_back_on_the_who_will_mentor_page
    expect(page.get_by_text("Who will mentor #{@ect_name}?")).to be_visible
    expect(page.url).to end_with("/school/ects/#{@ect.id}/mentorship/new?preselect=#{@mentor.id}")
  end

  def given_i_select_the_mentor
    page.get_by_role(:radio, name: @mentor_name).check
  end

  def then_the_mentor_i_previously_selected_is_still_selected
    expect(page.get_by_role(:radio, name: @mentor_name)).to be_checked
  end

  def then_i_should_be_taken_to_the_eligibility_page
    expect(page.url).to end_with("assign-existing-mentor/review-mentor-eligibility")
    expect(page.get_by_text("#{@mentor_name} can receive mentor training")).to be_visible
  end

  def then_i_should_be_taken_to_the_mentorship_confirmation_page
    expect(page.url).to end_with("/school/assign-existing-mentor/confirmation")
    expect(page.get_by_text("You’ve assigned #{@mentor_name} as a mentor for #{@ect_name}")).to be_visible
  end

  def given_i_click_on_back_to_your_ects
    page.get_by_role(:link, name: 'Back to your ECTs').click
  end

  def then_i_should_be_taken_to_the_ects_page
    expect(page.url).to end_with('/schools/home/ects')
  end

  def and_the_ect_is_shown_linked_to_the_mentor_just_registered
    expect(page.get_by_role(:link, name: @ect_name)).to be_visible
    expect(page.locator('dt', hasText: 'Mentor')).to be_visible
    expect(page.locator('dd', hasText: @mentor_name)).to be_visible
  end
end
