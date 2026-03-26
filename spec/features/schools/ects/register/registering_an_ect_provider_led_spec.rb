RSpec.describe "Registering an ECT with provider-led training", :enable_schools_interface do
  include_context "test TRS API returns a teacher"
  include ReusablePartnershipHelpers

  around do |example|
    travel_to(Date.new(2025, 9, 1)) { example.run }
  end

  scenario "selecting provider-led training and a lead provider" do
    given_i_have_reached_the_training_programme_step

    when_i_select_provider_led
    and_i_click_continue
    then_i_am_on_the_lead_provider_page

    when_i_try_to_skip_to_check_answers
    then_i_am_redirected_to_select_a_lead_provider

    when_i_select_a_lead_provider
    and_i_click_continue
    then_i_am_on_the_check_answers_page
    and_i_should_see_provider_led_with_lead_provider

    and_i_click_confirm_details
    then_i_am_on_the_confirmation_page
  end

  def given_i_have_reached_the_training_programme_step
    context = build_school_with_reusable_provider_led_partnership

    @school = context.school
    @current_contract_period = context.current_contract_period

    FactoryBot.create(:appropriate_body_period, name: "Golden Leaf Teaching Hub")

    reuse_finder = instance_double(SchoolPartnerships::FindReusablePartnership)
    allow(SchoolPartnerships::FindReusablePartnership).to receive(:new).and_return(reuse_finder)
    allow(reuse_finder).to receive(:call).and_return(nil)

    sign_in_as_school_user(school: @school)

    page.goto "/school/home/ects"
    page.get_by_role("link", name: "Register an ECT starting at your school").click
    page.get_by_role("link", name: "Continue").click

    page.get_by_label("trn").fill("9876543")
    page.get_by_label("day").fill("3")
    page.get_by_label("month").fill("2")
    page.get_by_label("year").fill("1977")
    page.get_by_role("button", name: "Continue").click

    page.get_by_label("Yes").check
    page.get_by_role("button", name: "Confirm and continue").click

    page.get_by_label(/email address/i).fill("example@example.com")
    page.get_by_role("button", name: "Continue").click

    start_date = @current_contract_period.started_on + 1.month
    page.get_by_label("day").fill(start_date.day.to_s)
    page.get_by_label("month").fill(start_date.month.to_s)
    page.get_by_label("year").fill(start_date.year.to_s)
    page.get_by_role("button", name: "Continue").click

    page.get_by_label("Full time").check
    page.get_by_role("button", name: "Continue").click

    page.get_by_role("combobox", name: "Enter appropriate body name")
        .first
        .select_option(value: "Golden Leaf Teaching Hub")
    page.get_by_role("button", name: "Continue").click

    expect(page).to have_path("/school/register-ect/training-programme")
  end

  def when_i_select_provider_led
    page.get_by_label("Provider-led").check
  end

  def and_i_click_continue
    page.get_by_role("button", name: "Continue").click
  end

  def then_i_am_on_the_lead_provider_page
    expect(page).to have_path("/school/register-ect/lead-provider")
  end

  def when_i_try_to_skip_to_check_answers
    page.goto "/school/register-ect/check-answers"
  end

  def then_i_am_redirected_to_select_a_lead_provider
    expect(page).to have_path("/school/register-ect/training-programme-change-lead-provider")
  end

  def when_i_select_a_lead_provider
    page.get_by_label("Orange Institute").check
  end

  def then_i_am_on_the_check_answers_page
    expect(page).to have_path("/school/register-ect/check-answers")
  end

  def and_i_should_see_provider_led_with_lead_provider
    expect(page.get_by_text("Provider-led")).to be_visible
    expect(page.get_by_text("Orange Institute")).to be_visible
  end

  def and_i_click_confirm_details
    page.get_by_role("button", name: "Confirm details").click
  end

  def then_i_am_on_the_confirmation_page
    expect(page).to have_path("/school/register-ect/confirmation")
  end
end
