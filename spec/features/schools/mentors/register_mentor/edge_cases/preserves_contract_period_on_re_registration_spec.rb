RSpec.describe "Registering a mentor" do
  include_context "test TRS API returns a teacher"
  include SchoolPartnershipHelpers

  let(:trn) { "3002586" }

  scenario "contract period is preserved when a mentor re-registers at a new school" do
    given_there_is_a_school_in_the_service
    and_the_school_is_in_a_partnership_with_a_lead_provider
    and_there_is_an_ect_with_no_mentor_registered_at_the_school
    and_there_is_a_mentor_previously_registered_in_an_older_contract_period
    and_i_sign_in_as_that_school_user
    and_i_am_on_the_schools_landing_page

    when_i_click_to_assign_a_mentor_to_the_ect
    then_i_am_in_the_requirements_page

    when_i_click_continue
    then_i_should_be_taken_to_the_find_mentor_page

    when_i_submit_the_find_mentor_form
    then_i_should_be_taken_to_the_review_mentor_details_page

    when_i_confirm_the_mentor_details
    then_i_should_be_taken_to_the_email_address_page

    when_i_enter_the_mentor_email_address
    and_i_click_continue
    then_i_should_be_taken_to_the_started_on_page
    when_i_submit_the_started_on_form
    then_i_should_be_taken_to_the_previous_training_period_details_page
    when_i_submit_the_previous_training_period_details_form
    then_i_should_be_taken_to_the_programme_choices_page
    when_i_select_same_programme_choices
    then_i_should_be_taken_to_the_check_answers_page

    when_i_click_confirm_details
    then_i_should_be_taken_to_the_confirmation_page
    and_the_new_training_period_should_preserve_the_original_contract_period
  end

private

  def given_there_is_a_school_in_the_service
    @school = FactoryBot.create(:school, urn: "1234567")
  end

  def and_the_school_is_in_a_partnership_with_a_lead_provider
    @contract_period_2025 = FactoryBot.create(:contract_period, :with_schedules, :current)
    @school_partnership = make_partnership_for(@school, @contract_period_2025)
    @lead_provider = @school_partnership.lead_provider_delivery_partnership.lead_provider
  end

  def and_there_is_an_ect_with_no_mentor_registered_at_the_school
    @active_lead_provider = FactoryBot.create(:active_lead_provider,
                                              lead_provider: @lead_provider,
                                              contract_period: @contract_period_2025)
    @ect = FactoryBot.create(:ect_at_school_period, :ongoing, school: @school)
    FactoryBot.create(:training_period, :provider_led, :ongoing,
                      ect_at_school_period: @ect,
                      school_partnership: FactoryBot.create(:school_partnership,
                                                            school: @school,
                                                            lead_provider_delivery_partnership: FactoryBot.create(:lead_provider_delivery_partnership,
                                                                                                                  active_lead_provider: @active_lead_provider)))
    @ect_name = Teachers::Name.new(@ect.teacher).full_name
  end

  def and_there_is_a_mentor_previously_registered_in_an_older_contract_period
    @contract_period_2024 = FactoryBot.create(:contract_period, :with_schedules, :previous)
    @another_school = FactoryBot.create(:school, urn: "7654321")
    @teacher = FactoryBot.create(:teacher, trn:, trs_first_name: "Kirk", trs_last_name: "Van Houten", corrected_name: nil)

    older_active_lead_provider = FactoryBot.create(:active_lead_provider,
                                                   lead_provider: @lead_provider,
                                                   contract_period: @contract_period_2024)

    @existing_mentor_at_school_period = FactoryBot.create(:mentor_at_school_period,
                                                          teacher: @teacher,
                                                          school: @another_school,
                                                          started_on: @contract_period_2024.started_on,
                                                          finished_on: @contract_period_2024.started_on + 6.months)

    FactoryBot.create(:training_period, :provider_led, :for_mentor, :with_only_expression_of_interest,
                      mentor_at_school_period: @existing_mentor_at_school_period,
                      started_on: @existing_mentor_at_school_period.started_on,
                      expression_of_interest: older_active_lead_provider)
  end

  def and_i_sign_in_as_that_school_user
    sign_in_as_school_user(school: @school)
  end

  def and_i_am_on_the_schools_landing_page
    path = "/school/home/ects"
    page.goto path
    expect(page).to have_path(path)
  end

  def when_i_click_to_assign_a_mentor_to_the_ect
    page.get_by_role("link", name: "Assign a mentor for this ECT").click
  end

  def then_i_am_in_the_requirements_page
    expect(page.get_by_text("What you'll need to add a new mentor for #{@ect_name}")).to be_visible
    expect(page.url).to end_with("/school/register-mentor/what-you-will-need?ect_id=#{@ect.id}")
  end

  def when_i_click_continue
    page.get_by_role("link", name: "Continue").click
  end

  def then_i_should_be_taken_to_the_find_mentor_page
    expect(page).to have_path("/school/register-mentor/find-mentor")
  end

  def when_i_submit_the_find_mentor_form
    page.get_by_label("trn").fill(trn)
    page.get_by_label("day").fill("3")
    page.get_by_label("month").fill("2")
    page.get_by_label("year").fill("1977")
    page.get_by_role("button", name: "Continue").click
  end

  def then_i_should_be_taken_to_the_review_mentor_details_page
    expect(page).to have_path("/school/register-mentor/review-mentor-details")
  end

  def when_i_confirm_the_mentor_details
    page.get_by_label("Yes").check
    page.get_by_role("button", name: "Confirm and continue").click
  end

  def then_i_should_be_taken_to_the_email_address_page
    expect(page).to have_path("/school/register-mentor/email-address")
  end

  def when_i_enter_the_mentor_email_address
    page.get_by_label("email").fill("kirk@springfield.com")
  end

  def and_i_click_continue
    page.get_by_role("button", name: "Continue").click
  end

  def then_i_should_be_taken_to_the_started_on_page
    expect(page).to have_path("/school/register-mentor/started-on")
  end

  def when_i_submit_the_started_on_form
    page.get_by_label("Day").fill("1")
    page.get_by_label("Month").fill("6")
    page.get_by_label("Year").fill("2025")
    page.get_by_role("button", name: "Continue").click
  end

  def then_i_should_be_taken_to_the_previous_training_period_details_page
    expect(page).to have_path("/school/register-mentor/previous-training-period-details")
  end

  def when_i_submit_the_previous_training_period_details_form
    page.get_by_role("button", name: "Continue").click
  end

  def then_i_should_be_taken_to_the_programme_choices_page
    expect(page).to have_path("/school/register-mentor/programme-choices")
  end

  def when_i_select_same_programme_choices
    page.get_by_label("Yes").check
    page.get_by_role("button", name: "Continue").click
  end

  def then_i_should_be_taken_to_the_check_answers_page
    expect(page).to have_path("/school/register-mentor/check-answers")
  end

  def when_i_click_confirm_details
    page.get_by_role("button", name: "Confirm details").click
  end

  def then_i_should_be_taken_to_the_confirmation_page
    expect(page).to have_path("/school/register-mentor/confirmation")
  end

  def and_the_new_training_period_should_preserve_the_original_contract_period
    new_mentor_at_school_period = @teacher.mentor_at_school_periods
                                          .excluding(@existing_mentor_at_school_period)
                                          .last
    new_training_period = new_mentor_at_school_period&.training_periods&.first

    expect(new_training_period).not_to be_nil
    expect(new_training_period.schedule.contract_period).to eq(@contract_period_2024)
  end
end
