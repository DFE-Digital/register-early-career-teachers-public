module DeclarationHelper
  DECLARATION_STATE_TAG_COLOURS = {
    "no_payment" => "light-blue",
    "eligible" => "turquoise",
    "payable" => "orange",
    "paid" => "green",
    "voided" => "red",
    "awaiting_clawback" => "pink",
    "clawed_back" => "purple",
  }.freeze

  DECLARATION_STATE_DISPLAY_NAMES = {
    "no_payment" => "Submitted",
    "eligible" => "Eligible",
    "payable" => "Payable",
    "paid" => "Paid",
    "voided" => "Voided",
    "awaiting_clawback" => "Awaiting clawback",
    "clawed_back" => "Clawed back",
  }.freeze

  DECLARATION_EVENT_STATE_NAMES = {
    "teacher_declaration_created" => "Submitted",
    "teacher_declaration_voided" => "Voided",
    "teacher_declaration_clawed_back" => "Clawed back",
  }.freeze

  def declaration_state_tag(declaration)
    state = declaration.overall_status
    govuk_tag(
      text: DECLARATION_STATE_DISPLAY_NAMES.fetch(state, state),
      colour: DECLARATION_STATE_TAG_COLOURS.fetch(state, "grey")
    )
  end

  def declaration_event_state_name(event)
    DECLARATION_EVENT_STATE_NAMES.fetch(event.event_type, event.heading)
  end

  def declaration_course_identifier(declaration)
    if declaration.for_ect?
      "ecf-induction"
    elsif declaration.for_mentor?
      "ecf-mentor"
    end
  end
end
