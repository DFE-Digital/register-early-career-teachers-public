describe Events::AppropriateBodyBackgroundJobAuthor do
  describe 'initialization' do
    it 'is initialized with an email, name and appropriate body id' do
      author = Events::AppropriateBodyBackgroundJobAuthor.new(email: 'test@test.org', name: 'Mr Test', appropriate_body_id: 123)

      expect(author.author_params).to eql(
        {
          email: 'test@test.org',
          name: 'Mr Test',
          appropriate_body_id: 123,
          author_type: 'appropriate_body_user'
        }
      )
    end
  end
end
