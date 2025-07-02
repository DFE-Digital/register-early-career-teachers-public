class Events::AppropriateBodyBackgroundJobAuthor
  attr_reader :email, :name, :appropriate_body_id

  def initialize(email:, name:, appropriate_body_id:)
    @email = email
    @name = name
    @appropriate_body_id = appropriate_body_id
  end

  def author_params
    {
      author_email: email,
      author_name: name,
      appropriate_body_id:,
      author_type: :appropriate_body_user,
    }
  end
end
