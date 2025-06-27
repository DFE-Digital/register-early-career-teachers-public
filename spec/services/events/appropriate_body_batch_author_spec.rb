RSpec.describe Events::AppropriateBodyBatchAuthor do
  subject(:author) do
    Events::AppropriateBodyBatchAuthor.new(
      email: 'test@test.org',
      name: 'Mr Test',
      appropriate_body_id: 123,
      batch_id: 456
    )
  end

  describe '#event_author_params' do
    it 'returns author name, email, type and associated appropriate body id' do
      expect(author.event_author_params).to eql(
        {
          author_name: 'Mr Test',
          author_email: 'test@test.org',
          author_type: :appropriate_body_user,
          appropriate_body_id: 123,
          pending_induction_submission_batch_id: 456,
        }
      )
    end
  end
end
