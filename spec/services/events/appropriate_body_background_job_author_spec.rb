RSpec.describe Events::AppropriateBodyBackgroundJobAuthor do
  subject(:author) do
    Events::AppropriateBodyBackgroundJobAuthor.new(
      email: 'test@test.org',
      name: 'Mr Test',
      appropriate_body_id: 123
    )
  end

  describe '#author_params' do
    it 'returns author name, email, type and associated appropriate body id' do
      expect(author.author_params).to eql(
        {
          author_name: 'Mr Test',
          author_email: 'test@test.org',
          author_type: :appropriate_body_user,
          appropriate_body_id: 123
        }
      )
    end
  end
end
