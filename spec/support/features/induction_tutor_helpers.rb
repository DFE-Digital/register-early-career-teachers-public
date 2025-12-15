module Features
  module InductionTutorHelpers
    def and_there_are_contract_periods
      @previous_contract_period = FactoryBot.create(:contract_period, :previous, :with_schedules)
      @current_contract_period  = FactoryBot.create(:contract_period, :current,  :with_schedules)
    end

    def and_the_details_are_confirmed_for_the_previous_contract_period
      @school.update(induction_tutor_last_nominated_in: @previous_contract_period)
    end

    def and_the_details_are_confirmed_for_the_current_contract_period
      @school.update(induction_tutor_last_nominated_in: @current_contract_period)
    end

    def and_i_sign_in_as_that_school_user
      sign_in_as_school_user(school: @school)
    end

    def and_i_click_continue
      page.get_by_role("button", name: "Continue").click
    end

    def when_i_click_continue_from_confirmation_page
      page.get_by_role("link", name: "Continue").click
    end

    def when_i_click_confirm
      page.get_by_role("button", name: "Confirm induction tutor").click
    end

    def when_i_click_cancel_and_go_back
      page.get_by_role("link", name: "Cancel and go back").click
    end

    def then_i_should_see_the_school_home_page
      expect(page).to have_path("/school/home/ects")
      expect(page.get_by_text("Early career teachers (ECT)")).to be_visible
    end

    def and_the_navigation_bar_is_visible
      expect(page.locator(".govuk-service-navigation__wrapper")).to be_visible
    end

    def and_the_navigation_bar_is_not_visible
      expect(page.locator(".govuk-service-navigation__wrapper")).not_to be_visible
    end

    def when_i_enter_invalid_details_for_the_induction_tutor
      page.get_by_label("Email").fill("invalid-email")
    end

    def then_i_am_taken_to_the_wizard_start_page
      expect(page).to have_path("#{base_page}/edit")
    end

    def then_i_should_be_taken_to_the_check_answers_page
      expect(page).to have_path("#{base_page}/check-answers")
    end

    def then_i_should_be_taken_to_the_confirmation_page
      expect(page).to have_path("#{base_page}/confirmation")
    end

    def when_i_enter_valid_details_for_the_induction_tutor
      page.get_by_label("Full name").fill("New Name")
      page.get_by_label("Email").fill("new.name@example.com")
    end

    alias_method :and_i_enter_valid_details, :when_i_enter_valid_details_for_the_induction_tutor

    def then_i_should_see_error_messages_indicating_what_i_need_to_fix
      expect(page.get_by_role("heading", name: "There is a problem")).to be_visible
      expect(
        page.locator(".govuk-error-summary a")
            .and(page.get_by_text("Enter an email address in the correct format, like name@example.com"))
      ).to be_visible
    end

    def and_the_data_i_entered_is_saved
      expect(page.get_by_label("Full name").input_value).to eq("New Name")
      expect(page.get_by_label("Email").input_value).to eq("new.name@example.com")
    end

    def and_the_induction_tutor_details_should_have_changed
      expect(@school.reload.induction_tutor_name).to eq("New Name")
      expect(@school.induction_tutor_email).to eq("new.name@example.com")
    end

    def and_the_new_name_and_email_should_be_displayed_on_the_check_answers_page
      expect(page.get_by_text("new.name@example.com")).to be_visible
      expect(page.get_by_text("New Name")).to be_visible
    end

    def and_the_induction_tutor_details_should_be_confirmed_in_the_current_contract_period
      @school.reload

      expect(@school.induction_tutor_last_nominated_in).to be_present
      expect(@school.induction_tutor_last_nominated_in.year).to eq(@current_contract_period.year)
    end
  end
end
