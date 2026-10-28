class Events::AppropriateBodyAPIAuthor
  attr_reader :appropriate_body_period

  def initialize(appropriate_body_period:)
    @appropriate_body_period = appropriate_body_period
  end

  def event_author_params
    {
      author_type: :appropriate_body_api,
      author_name: appropriate_body_period.name,
    }
  end
end
