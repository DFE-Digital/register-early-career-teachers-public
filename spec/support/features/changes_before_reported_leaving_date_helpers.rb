module ChangesBeforeReportedLeavingDateHelpers
private

  # Setup
  def given_there_is_a_school
    @school = FactoryBot.create(:school, :state_funded)
  end

  def and_there_is_another_school
    @another_school = FactoryBot.create(:school, :state_funded)
  end

  def and_there_is_an_ect_at_the_school
    @teacher = FactoryBot.create(:teacher, corrected_name: "Mr Teacher")
    @ect_at_school_period = FactoryBot.create(
      :ect_at_school_period,
      :ongoing,
      school: @school,
      teacher: @teacher,
      started_on: 2.months.ago
    )
  end

  def given_i_am_logged_in_as_a_school_user(school)
    sign_in_as_school_user(school:)
  end
  alias_method :and_i_am_logged_in_as_a_school_user, :given_i_am_logged_in_as_a_school_user

  def given_i_am_logged_in_as_an_admin
    sign_in_as_dfe_user(role: :admin)
  end
  alias_method :and_i_am_logged_in_as_an_admin, :given_i_am_logged_in_as_an_admin

  def and_i_report_the_ect_as_leaving(on:)
    when_i_visit_the_ect_page
    leaving_cta = page.get_by_role("link", name: "Tell us if Mr Teacher is leaving permanently")
    leaving_cta.click
    leaving_date_question = "When did or when will Mr Teacher be leaving your school?"
    leaving_date_fieldset = page.locator("fieldset", hasText: leaving_date_question)
    leaving_date_fieldset.get_by_label("Day").fill(on.day.to_s)
    leaving_date_fieldset.get_by_label("Month").fill(on.month.to_s)
    leaving_date_fieldset.get_by_label("Year").fill(on.year.to_s)
    and_i_continue
    and_i_confirm_and_continue
    confirmation_message = "Mr Teacher will be removed from your school’s ECT list"
    then_panel_is_visible_with(message: confirmation_message)
  end

  def given_the_ect_has_been_registered_by_another_school(on:)
    admin = Sessions::Users::SchoolPersona.new(
      email: "admin@example.com",
      name: "Admin",
      school_urn: @another_school.urn
    )
    appropriate_body = FactoryBot.create(:appropriate_body_period, :teaching_school_hub)
    Schools::RegisterECT.new(
      trn: @teacher.trn,
      trs_first_name: @teacher.trs_first_name,
      trs_last_name: @teacher.trs_last_name,
      corrected_name: @teacher.corrected_name,
      email: "test@example.com",
      school: @another_school,
      started_on: on,
      school_reported_appropriate_body: appropriate_body,
      training_programme: "school_led",
      working_pattern: "full_time",
      author: admin,
      lead_provider: nil
    ).register!
  end

  # Navigation
  def when_i_visit_the_ect_page
    page.goto(schools_ect_path(@ect_at_school_period))
    expect(page.locator("h1")).to have_text("Mr Teacher")
  end

  def when_i_visit_the_schools_landing_page
    page.goto(schools_ects_home_path)
  end

  def when_i_visit_the_admin_teacher_school_page
    page.goto(admin_teacher_school_path(@ect_at_school_period.teacher))
  end

  def when_i_visit_the_admin_teacher_training_page
    page.goto(admin_teacher_training_path(@ect_at_school_period.teacher))
  end

  # Actions
  def when_i_continue
    page.get_by_role("button", name: "Continue").click
  end
  alias_method :and_i_continue, :when_i_continue

  def when_i_confirm_and_continue
    page.get_by_role("button", name: "Confirm and continue").click
  end
  alias_method :and_i_confirm_and_continue, :when_i_confirm_and_continue

  def when_i_confirm_the_change
    page.get_by_role("button", name: "Confirm change").click
  end
  alias_method :and_i_confirm_the_change, :when_i_confirm_the_change

  def when_i_confirm_details
    page.get_by_role("button", name: "Confirm details").click
  end
  alias_method :and_i_confirm_details, :when_i_confirm_details

  # Assertions
  def then_i_am_asked_to_check_and_confirm_the_change
    heading = page.locator("h1", hasText: "Check and confirm change")
    expect(heading).to be_visible
  end

  def then_panel_is_visible_with(message:)
    panel = page.locator(".govuk-panel")
    expect(panel).to have_text(message)
  end

  def then_i_see_the_correct_ect_at_school_periods(*period_hashes)
    summary_cards = page.locator(".govuk-summary-card").all
    expect(summary_cards.size).to eq(period_hashes.size)

    period_hashes.each do |period_hash|
      school = period_hash[:school]
      summary_card = summary_cards.find { it.inner_text.include?(school.name) }

      urn_row = summary_card
        .locator("dl dt", hasText: "School URN")
        .locator("..") # Navigate "up" to the parent summary list row
      expect(urn_row.locator("dd")).to have_text(school.urn.to_s)

      start_date_row = summary_card
        .locator("dl dt", hasText: "School start date")
        .locator("..")
      start_date = period_hash[:start].to_fs(:govuk)
      expect(start_date_row.locator("dd")).to have_text(start_date)

      end_date_row = summary_card
        .locator("dl dt", hasText: "School end date")
        .locator("..")
      end_date = period_hash[:end]&.to_fs(:govuk) || "No end date recorded"
      expect(end_date_row.locator("dd")).to have_text(end_date)
    end
  end

  def then_i_see_the_correct_training_periods(*period_hashes)
    summary_cards = page.locator(".govuk-summary-card").all
    expect(summary_cards.size).to eq(period_hashes.size)

    period_hashes.each_with_index do |period_hash, index|
      summary_card = summary_cards[index]

      training_row = summary_card
        .locator("dl dt", hasText: "Training programme")
        .locator("..") # Navigate "up" to the parent summary list row
      expect(training_row.locator("dd")).to have_text(period_hash[:type])

      school_row = summary_card
        .locator("dl dt", hasText: "School")
        .locator("..")
      expect(school_row.locator("dd")).to have_text(period_hash[:school].name)

      if period_hash.key?(:lead_provider)
        lead_provider_row = summary_card
          .locator("dl dt", hasText: "Lead provider")
          .locator("..")
        lead_provider_name = period_hash[:lead_provider].name
        expect(lead_provider_row.locator("dd")).to have_text(lead_provider_name)
      end

      start_date_row = summary_card
        .locator("dl dt", hasText: "Start date")
        .locator("..")
      start_date = period_hash[:start].to_fs(:govuk)
      expect(start_date_row.locator("dd")).to have_text(start_date)

      end_date_row = summary_card
        .locator("dl dt", hasText: "End date")
        .locator("..")
      end_date = period_hash[:end]&.to_fs(:govuk) || "No end date recorded"
      expect(end_date_row.locator("dd")).to have_text(end_date)
    end
  end
end
