# Event recording requires #author_params
#
class Events::AppropriateBodyBatchAuthor
  attr_reader :email, :name, :appropriate_body_id, :batch_id

  def initialize(email:, name:, appropriate_body_id:, batch_id:)
    @email = email
    @name = name
    @appropriate_body_id = appropriate_body_id
    @batch_id = batch_id
  end

  def event_author_params
    {
      author_email: email,
      author_name: name,
      appropriate_body_id:,
      author_type: :appropriate_body_user,
      pending_induction_submission_batch_id: batch_id,
    }
  end
end
