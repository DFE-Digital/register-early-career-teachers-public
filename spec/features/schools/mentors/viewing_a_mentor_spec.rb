RSpec.describe "Viewing a mentor" do
  before do
    allow(Rails.application.config).to receive(:enable_schools_interface).and_return(true)
  end

  scenario "Happy path" do
    given_that_i_have_an_active_mentor_with_an_ect
    and_i_sign_in_as_a_school
    when_i_visit_the_index_page
    and_i_click_on_a_mentor
    then_i_am_on_the_mentor_details_page

    given_i_click_on_an_assigned_ect
    and_i_am_on_the_ect_details_page
    when_i_click_the_back_link
    then_i_am_back_on_the_mentor_details_page

    given_i_click_the_back_link
    then_i_am_on_the_mentors_index_page
  end

  scenario "Mentor training – EOI (awaiting confirmation)" do
    given_an_eligible_mentor_with_eoi_training
    and_i_sign_in_as_a_school
    when_i_visit_the_index_page
    and_i_click_on_the_current_mentor

    then_i_see_ecte_mentor_training_details
    and_i_see_lead_provider("Hidden leaf village")
    and_i_see_hint("Awaiting confirmation by Hidden leaf village")
    and_i_see_delivery_partner("Yet to be reported by the lead provider")
  end

  scenario "Mentor training – confirmed partnership (LP+DP shown)" do
    given_an_eligible_mentor_with_confirmed_training
    and_i_sign_in_as_a_school
    when_i_visit_the_index_page
    and_i_click_on_the_current_mentor

    then_i_see_ecte_mentor_training_details
    and_i_see_lead_provider("Hidden leaf village")
    and_i_see_hint("Confirmed by Hidden leaf village")
    and_i_see_delivery_partner("Artisan Education Group")
    and_i_see_change_dp_hint
  end

  scenario "Mentor training – ineligible (completed)" do
    given_an_ineligible_mentor_completed_on(Date.new(2024, 1, 1))
    and_i_sign_in_as_a_school
    when_i_visit_the_index_page
    and_i_click_on_the_current_mentor

    then_i_see_text("Naruto Uzumaki completed mentor training on 1 January 2024.")
    and_i_do_not_see_summary_rows
  end

  scenario "Mentor training – ineligible (started_not_completed)" do
    given_an_ineligible_mentor_started_not_completed
    and_i_sign_in_as_a_school
    when_i_visit_the_index_page
    and_i_click_on_the_current_mentor

    then_i_see_text(/cannot do further mentor training/i)
    and_i_do_not_see_summary_rows
  end

  scenario "Mentor training – nothing to show (no current_or_future period)" do
    given_an_eligible_mentor_with_only_past_training
    and_i_sign_in_as_a_school
    when_i_visit_the_index_page
    and_i_click_on_the_current_mentor

    then_i_do_not_see_ecte_mentor_training_details
    and_i_do_not_see_summary_rows
  end

  def given_that_i_have_an_active_mentor_with_an_ect
    start_date = Date.new(2023, 9, 1)

    @school = FactoryBot.create(:school, urn: "1234567")
    @mentor_teacher = FactoryBot.create(:teacher, trs_first_name: "Naruto", trs_last_name: "Uzumaki")
    @mentor = FactoryBot.create(:mentor_at_school_period,
                                teacher: @mentor_teacher,
                                school: @school,
                                started_on: start_date,
                                finished_on: nil,
                                id: 1)

    @ect_teacher = FactoryBot.create(:teacher, trs_first_name: "Boruto", trs_last_name: "Uzumaki")
    @ect = FactoryBot.create(:ect_at_school_period,
                             teacher: @ect_teacher,
                             school: @school,
                             started_on: start_date,
                             finished_on: nil)

    FactoryBot.create(:training_period, :ongoing, :provider_led, :for_ect, ect_at_school_period: @ect)
    FactoryBot.create(:mentorship_period, mentor: @mentor, mentee: @ect, started_on: start_date, finished_on: nil)
  end

  def given_i_click_on_an_assigned_ect
    page.get_by_role("link", name: "Boruto Uzumaki").click
  end

  def and_i_am_on_the_ect_details_page
    expect(page.url).to end_with(schools_ect_path(@ect, back_to_mentor: true, mentor_id: @mentor.id))
  end

  def then_i_am_back_on_the_mentor_details_page
    expect(page).to have_path(schools_mentor_path(@mentor))
  end

  def and_i_sign_in_as_a_school
    sign_in_as_school_user(school: @school)
  end

  def when_i_visit_the_index_page
    page.goto(schools_mentors_home_path)
  end

  def and_i_click_on_a_mentor
    page.get_by_role("link", name: "Naruto Uzumaki").click
  end

  def then_i_am_on_the_mentor_details_page
    expect(page).to have_path("/schools/mentors/#{@mentor.id}")
  end

  def given_i_click_the_back_link
    page.locator('a.govuk-back-link').first.click
  end

  def when_i_click_the_back_link
    page.locator('a.govuk-back-link').first.click
  end

  def then_i_am_on_the_mentors_index_page
    expect(page).to have_path("/schools/home/mentors")
  end

  def build_school_and_mentor
    @school = FactoryBot.create(:school, urn: "1234567")
    @mentor_teacher = FactoryBot.create(:teacher, trs_first_name: "Naruto", trs_last_name: "Uzumaki")
    @mentor = FactoryBot.create(:mentor_at_school_period,
                                teacher: @mentor_teacher,
                                school: @school,
                                started_on: Date.new(2023, 9, 1),
                                finished_on: nil,
                                id: 1)
    @ects = []
  end

  def lp_dp_and_partnership
    @lead_provider = FactoryBot.create(:lead_provider, name: "Hidden leaf village")
    @active_lp     = FactoryBot.create(:active_lead_provider, lead_provider: @lead_provider)
    @dp            = FactoryBot.create(:delivery_partner, name: "Artisan Education Group")
    @lpdp          = FactoryBot.create(:lead_provider_delivery_partnership,
                                       active_lead_provider: @active_lp,
                                       delivery_partner: @dp)
    @school_partnership = FactoryBot.create(:school_partnership,
                                            lead_provider_delivery_partnership: @lpdp,
                                            school: @school)
  end

  def given_an_eligible_mentor_with_eoi_training
    build_school_and_mentor
    lp_dp_and_partnership
    FactoryBot.create(:training_period, :provider_led, :for_mentor,
                      mentor_at_school_period: @mentor,
                      started_on: Time.zone.today.beginning_of_month,
                      finished_on: nil,
                      school_partnership: nil,
                      expression_of_interest: @active_lp)
  end

  def given_an_eligible_mentor_with_confirmed_training
    build_school_and_mentor
    lp_dp_and_partnership
    FactoryBot.create(:training_period, :provider_led, :for_mentor,
                      mentor_at_school_period: @mentor,
                      started_on: Time.zone.today.beginning_of_month,
                      finished_on: nil,
                      school_partnership: @school_partnership)
  end

  def given_an_ineligible_mentor_completed_on(date)
    build_school_and_mentor
    @mentor_teacher.update!(
      mentor_became_ineligible_for_funding_on: date,
      mentor_became_ineligible_for_funding_reason: "completed_declaration_received"
    )
  end

  def given_an_ineligible_mentor_started_not_completed
    build_school_and_mentor
    @mentor_teacher.update!(
      mentor_became_ineligible_for_funding_on: Date.new(2024, 1, 1),
      mentor_became_ineligible_for_funding_reason: "started_not_completed"
    )
  end

  def given_an_eligible_mentor_with_only_past_training
    build_school_and_mentor
    lp_dp_and_partnership
    started  = Date.new(2023, 10, 1)
    finished = Date.new(2023, 12, 1)
    FactoryBot.create(:training_period, :provider_led, :for_mentor,
                      mentor_at_school_period: @mentor,
                      started_on: started, finished_on: finished,
                      school_partnership: @school_partnership)
  end

  def and_i_click_on_the_current_mentor
    page.get_by_role("link", name: "Naruto Uzumaki").click
  end

  def then_i_see_ecte_mentor_training_details
    expect(page.locator('h2.govuk-heading-m:has-text("ECTE mentor training details")')).to be_visible
  end

  def then_i_do_not_see_ecte_mentor_training_details
    expect(page.locator('h2.govuk-heading-m:has-text("ECTE mentor training details")')).to have_count(0)
  end

  def and_i_see_lead_provider(name)
    row = page.locator('.govuk-summary-list__row:has(dt.govuk-summary-list__key:has-text("Lead provider"))')
    expect(row.locator('dd.govuk-summary-list__value')).to be_visible
    expect(row.locator(%(dd.govuk-summary-list__value:has-text("#{name}")))).to be_visible
  end

  def and_i_see_delivery_partner(text_or_name)
    row = page.locator('.govuk-summary-list__row:has(dt.govuk-summary-list__key:has-text("Delivery partner"))')
    expect(row.locator('dd.govuk-summary-list__value')).to be_visible
    expect(row.locator(%(dd.govuk-summary-list__value:has-text("#{text_or_name}")))).to be_visible
  end

  def and_i_see_change_dp_hint
    expect(page.locator(%(.govuk-hint:has-text("To change the delivery partner, you must contact the lead provider")))).to be_visible
  end

  def and_i_see_hint(str_or_regex)
    if str_or_regex.is_a?(String)
      expect(page.locator(%(.govuk-hint:has-text("#{str_or_regex}")))).to be_visible
    else
      expect(page.locator("text=/#{str_or_regex.source}/i")).to be_visible
    end
  end

  def and_i_do_not_see_summary_rows
    expect(page.locator('.govuk-summary-list__row:has(dt.govuk-summary-list__key:has-text("Lead provider"))')).to have_count(0)
    expect(page.locator('.govuk-summary-list__row:has(dt.govuk-summary-list__key:has-text("Delivery partner"))')).to have_count(0)
  end

  def then_i_see_text(text_or_regex)
    if text_or_regex.is_a?(String)
      expect(page.locator("text=#{text_or_regex}")).to be_visible
    else
      expect(page.locator("text=/#{text_or_regex.source}/i")).to be_visible
    end
  end
end
