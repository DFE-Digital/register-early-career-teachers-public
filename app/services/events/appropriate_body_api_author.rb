class Events::AppropriateBodyAPIAuthor
  attr_reader :appropriate_body_period_id, :email, :name

  def initialize(appropriate_body_period:, email:)
    @appropriate_body_period_id = appropriate_body_period.id
    @email = email
    @name = appropriate_body_period.name
  end

  def event_author_params
    {
      author_type: :appropriate_body_user,
      author_name: name,
      author_email: email,
      appropriate_body_period_id:,
    }
  end

  def dfe_user? = false
  def appropriate_body_user? = true
end
