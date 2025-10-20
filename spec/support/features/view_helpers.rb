module Features
  module ViewHelpers
    def given_i_click_the_back_link
      page.locator("a.govuk-back-link").click
    end

    alias_method :when_i_click_the_back_link, :given_i_click_the_back_link
    alias_method :and_i_click_the_back_link, :given_i_click_the_back_link

    def given_i_click_continue
      page.get_by_role("button", name: "Continue").click
    end

    alias_method :when_i_click_continue, :given_i_click_continue
    alias_method :and_i_click_continue, :given_i_click_continue
  end
end
