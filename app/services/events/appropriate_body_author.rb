class Events::AppropriateBodyAuthor
  attr_reader :appropriate_body_period

  def initialize(appropriate_body_period:)
    @appropriate_body_period = appropriate_body_period
  end

  def event_author_params
    {
      author_type: :appropriate_body_user,
      author_name: appropriate_body_period.name,
      appropriate_body_period_id: appropriate_body_period.id,
    }
  end
end
