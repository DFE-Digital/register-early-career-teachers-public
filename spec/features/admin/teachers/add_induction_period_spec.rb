describe "Admin adds an induction period" do
  before do
    allow(Rails.application.config)
      .to receive(:enable_bulk_claim)
      .and_return(use_new_programme_types)
    sign_in_as_dfe_user(role: :admin)
  end

  context "using induction programmes" do
    let(:use_new_programme_types) { false }

    it "adds a closed induction period" do
      given_an_appropriate_body_exists(name: "Test Appropriate Body")
      given_a_teacher_exists(first_name: "Test", last_name: "Person")
      when_i_go_to_the_teacher_page
      then_there_is_no_induction_summary
      and_there_are_no_past_induction_periods

      when_i_click_the_add_an_induction_period_link
      then_there_is_a_form_to_add_an_induction_period(
        for_teacher: "Test Person"
      )

      when_i_fill_in_the_form_with(
        appropriate_body: "Test Appropriate Body",
        start_date: "1-1-2024",
        end_date: "1-1-2025",
        number_of_terms: "2",
        induction_programme: "Full induction programme"
      )
      and_i_submit_the_form
      then_i_see_a_success_message
      and_there_is_an_induction_summary
      and_there_is_a_past_induction_period(
        appropriate_body: "Test Appropriate Body"
      )
    end

    it "adds an open induction period" do
      given_an_appropriate_body_exists(name: "Test Appropriate Body")
      given_a_teacher_exists(first_name: "Test", last_name: "Person")
      when_i_go_to_the_teacher_page
      then_there_is_no_induction_summary
      and_there_are_no_past_induction_periods

      when_i_click_the_add_an_induction_period_link
      then_there_is_a_form_to_add_an_induction_period(
        for_teacher: "Test Person"
      )

      when_i_fill_in_the_form_with(
        appropriate_body: "Test Appropriate Body",
        start_date: "1-1-2024",
        induction_programme: "Full induction programme"
      )
      and_i_submit_the_form
      then_i_see_a_success_message
      and_there_is_an_induction_summary
      and_there_is_a_current_induction_period(
        appropriate_body: "Test Appropriate Body"
      )
    end
  end

  context "using training programmes" do
    let(:use_new_programme_types) { true }

    it "adds a closed induction period" do
      given_an_appropriate_body_exists(name: "Test Appropriate Body")
      given_a_teacher_exists(first_name: "Test", last_name: "Person")
      when_i_go_to_the_teacher_page
      then_there_is_no_induction_summary
      and_there_are_no_past_induction_periods

      when_i_click_the_add_an_induction_period_link
      then_there_is_a_form_to_add_an_induction_period(
        for_teacher: "Test Person"
      )

      when_i_fill_in_the_form_with(
        appropriate_body: "Test Appropriate Body",
        start_date: "1-1-2024",
        end_date: "1-1-2025",
        number_of_terms: "2",
        induction_programme: "Provider-led"
      )
      and_i_submit_the_form
      then_i_see_a_success_message
      and_there_is_an_induction_summary
      and_there_is_a_past_induction_period(
        appropriate_body: "Test Appropriate Body"
      )
    end

    it "adds an open induction period" do
      given_an_appropriate_body_exists(name: "Test Appropriate Body")
      given_a_teacher_exists(first_name: "Test", last_name: "Person")
      when_i_go_to_the_teacher_page
      then_there_is_no_induction_summary
      and_there_are_no_past_induction_periods

      when_i_click_the_add_an_induction_period_link
      then_there_is_a_form_to_add_an_induction_period(
        for_teacher: "Test Person"
      )

      when_i_fill_in_the_form_with(
        appropriate_body: "Test Appropriate Body",
        start_date: "1-1-2024",
        induction_programme: "Provider-led"
      )
      and_i_submit_the_form
      then_i_see_a_success_message
      and_there_is_an_induction_summary
      and_there_is_a_current_induction_period(
        appropriate_body: "Test Appropriate Body"
      )
    end
  end

private

  def given_an_appropriate_body_exists(name:)
    FactoryBot.create(:appropriate_body, name:)
  end

  def given_a_teacher_exists(first_name:, last_name:)
    @teacher = FactoryBot.create(
      :teacher,
      trs_first_name: first_name,
      trs_last_name: last_name
    )
  end

  def when_i_go_to_the_teacher_page
    page.goto(admin_teacher_path(@teacher))
  end

  def then_there_is_no_induction_summary
    expect(page.locator("h2", hasText: "Induction summary")).not_to be_visible
  end

  def and_there_are_no_past_induction_periods
    expect(page.locator("h2", hasText: "Past induction periods"))
      .not_to be_visible
  end

  def when_i_click_the_add_an_induction_period_link
    page.get_by_role("link", name: "Add an induction period").click
  end

  def then_there_is_a_form_to_add_an_induction_period(for_teacher:)
    form_heading = page.locator(
      "h1",
      hasText: "Add induction period for #{for_teacher}"
    )
    expect(form_heading).to be_visible
  end

  def when_i_fill_in_the_form_with(
    appropriate_body:,
    start_date:,
    induction_programme: nil,
    end_date: nil,
    number_of_terms: nil
  )
    appropriate_body_label = <<~TXT
      Which appropriate body was this induction period completed with
    TXT
    page.get_by_label(appropriate_body_label)
      .select_option(label: appropriate_body)

    start_date_fieldset = page.locator("fieldset", hasText: "Start date")
    day, month, year = start_date.split("-")
    start_date_fieldset.get_by_label("Day").fill(day)
    start_date_fieldset.get_by_label("Month").fill(month)
    start_date_fieldset.get_by_label("Year").fill(year)

    if end_date.present?
      end_date_fieldset = page.locator("fieldset", hasText: "End date")
      day, month, year = end_date.split("-")
      end_date_fieldset.get_by_label("Day").fill(day)
      end_date_fieldset.get_by_label("Month").fill(month)
      end_date_fieldset.get_by_label("Year").fill(year)
    end

    if number_of_terms.present?
      page.get_by_label("Number of terms").fill(number_of_terms)
    end

    programme_fieldset = page.locator(
      "fieldset",
      hasText: "Induction programme"
    )
    programme_fieldset.get_by_label(induction_programme).check
  end

  def and_i_submit_the_form
    page.locator("button[type=submit]", hasText: "Save").click
  end

  def then_i_see_a_success_message
    expect(page.locator(".govuk-notification-banner"))
      .to have_text("Induction period created successfully")
  end

  def and_there_is_an_induction_summary
    expect(page.locator("h2", hasText: "Induction summary")).to be_visible
  end

  def and_there_is_a_past_induction_period(appropriate_body:)
    expect(page.locator("h2", hasText: "Past induction periods")).to be_visible
    expect(page.locator(".govuk-summary-card", hasText: appropriate_body))
      .to be_visible
  end

  def and_there_is_a_current_induction_period(appropriate_body:)
    expect(page.locator("h2", hasText: "Current induction period"))
      .to be_visible
    expect(page.locator(".govuk-summary-card", hasText: appropriate_body))
      .to be_visible
  end
end
