module ContentHelper
  def generic_email_label
    safe_join([
      "Do not use a generic email like ",
      govuk_link_to("headteacher@school.com", "#", no_visited_state: true),
      "."
    ])
  end
end
