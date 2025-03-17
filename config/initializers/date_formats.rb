# https://www.gov.uk/guidance/style-guide/a-to-z#dates
Date::DATE_FORMATS[:govuk]        = "%-d %B %Y" # 2 January 1998
Date::DATE_FORMATS[:govuk_short]  = "%-d %b %Y" # 2 Jan 1998
Date::DATE_FORMATS[:govuk_approx] = "%B %Y"     # January 1998

# https://www.gov.uk/guidance/style-guide/a-to-z#times
Time::DATE_FORMATS[:govuk] = %(#{Date::DATE_FORMATS[:govuk]}, %-l:%M%P)             # 2 January 1998, 5:30pm
Time::DATE_FORMATS[:govuk_short] = %(#{Date::DATE_FORMATS[:govuk_short]}, %-l:%M%P) # 2 Jan 1998, 5:30pm
