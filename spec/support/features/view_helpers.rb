module Features
  module ViewHelpers
    def given_i_click_the_back_link
      page.locator('a.govuk-back-link').click
    end

    alias_method :when_i_click_back_link, :given_i_click_the_back_link
    alias_method :and_i_click_back_link, :given_i_click_the_back_link
  end
end
