describe 'Events::Metadata' do
  describe 'initialisation' do
    it 'cannot be instantiated with new' do
      expect { Events::Metadata.new }.to raise_error(NoMethodError, /private method/)
    end

    describe '.with_author_but_no_appropriate_body' do
      subject { Events::Metadata.with_author_but_no_appropriate_body(author:) }

      context 'when no author is present' do
        let(:author) { nil }

        it 'fails with MissingAuthor' do
          expect { subject }.to raise_error(Events::Metadata::MissingAuthorError)
        end
      end

      context 'when the author is present' do
        let(:author) { FactoryBot.create(:appropriate_body_user, :at_random_appropriate_body) }

        it 'assigns the author correctly' do
          expect(subject.author).to eql(author)
        end
      end
    end

    describe '.with_author_and_appropriate_body' do
      subject { Events::Metadata.with_author_and_appropriate_body(author:, appropriate_body:) }

      context 'when no author is present but an appropriate body is' do
        let(:author) { nil }
        let(:appropriate_body) { FactoryBot.create(:appropriate_body) }

        it 'fails with MissingAuthorError' do
          expect { subject }.to raise_error(Events::Metadata::MissingAuthorError)
        end
      end

      context 'when author is present but appropriate body is not' do
        let(:author) { FactoryBot.create(:appropriate_body_user, :at_random_appropriate_body) }
        let(:appropriate_body) { nil }

        it 'fails with MissingAppropriateBodyError' do
          expect { subject }.to raise_error(Events::Metadata::MissingAppropriateBodyError)
        end
      end

      context 'when both author and appropriate_body are present' do
        let(:author) { FactoryBot.create(:appropriate_body_user, :at_random_appropriate_body) }
        let(:appropriate_body) { FactoryBot.create(:appropriate_body) }

        it 'assigns both the author and appropriate body correctly' do
          expect(subject.author).to eql(author)
          expect(subject.appropriate_body).to eql(appropriate_body)
        end
      end
    end
  end

  describe '#to_hash (splattable)' do
    subject { Events::Metadata.with_author_and_appropriate_body(author:, appropriate_body:) }

    let(:author) { FactoryBot.create(:appropriate_body_user, :at_random_appropriate_body) }
    let(:appropriate_body) { FactoryBot.create(:appropriate_body) }

    it 'returns a hash containing the author and appropriate body' do
      expect(subject.to_hash).to eql({ author:, appropriate_body: })
    end
  end
end
