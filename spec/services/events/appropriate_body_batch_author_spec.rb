RSpec.describe Events::AppropriateBodyBatchAuthor do
  subject(:author) do
    Events::AppropriateBodyBatchAuthor.new(
      email: 'test@test.org',
      name: 'Mr Test',
      appropriate_body_id: batch.appropriate_body.id,
      batch_id: batch.id
    )
  end

  let(:batch) do
    FactoryBot.create(:pending_induction_submission_batch, :claim)
  end

  describe '#event_author_params' do
    it 'returns author name, email, type and associated appropriate body id' do
      expect(author.event_author_params).to eql({
        author_name: 'Mr Test',
        author_email: 'test@test.org',
        author_type: :appropriate_body_user,
        appropriate_body_id: batch.appropriate_body.id,
      })
    end
  end

  describe '#relationship_attributes' do
    it 'returns associated batch' do
      expect(author.relationship_attributes).to eql({
        pending_induction_submission_batch: batch,
      })
    end
  end
end
