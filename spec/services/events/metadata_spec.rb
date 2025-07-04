RSpec.describe Events::Metadata do
  let(:author) { FactoryBot.create(:user) }
  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }

  describe '#initialize' do
    it 'can be created without any parameters' do
      expect { described_class.new }.not_to raise_error
    end

    it 'allows author to be nil' do
      metadata = described_class.new

      expect(metadata.author).to be_nil
      expect(metadata.appropriate_body).to be_nil
    end

    it 'sets author and allows nil for other attributes' do
      metadata = described_class.new(author:)

      expect(metadata.author).to eq(author)
      expect(metadata.appropriate_body).to be_nil
      expect(metadata.description).to be_nil
    end

    it 'sets all provided attributes' do
      metadata = described_class.new(
        author:,
        appropriate_body:,
        description: 'Test description',
        mentor_id: 123,
        mentee_id: 456,
        batch_id: 789
      )

      expect(metadata.author).to eq(author)
      expect(metadata.appropriate_body).to eq(appropriate_body)
      expect(metadata.description).to eq('Test description')
      expect(metadata.mentor_id).to eq(123)
      expect(metadata.mentee_id).to eq(456)
      expect(metadata.batch_id).to eq(789)
    end
  end

  describe '#to_h' do
    it 'returns a hash with only non-nil values' do
      metadata = described_class.new(
        author:,
        appropriate_body:,
        description: 'Test description',
        mentor_id: nil,
        batch_id: 123
      )

      result = metadata.to_h

      expect(result).to eq({
        author:,
        appropriate_body:,
        description: 'Test description',
        batch_id: 123
      })
      expect(result).not_to have_key(:mentor_id)
    end

    it 'can be splatted into method calls' do
      metadata = described_class.new(
        author:,
        appropriate_body:,
        description: 'Test description'
      )

      result = { event_type: 'test', **metadata.to_h }

      expect(result).to include(
        event_type: 'test',
        author:,
        appropriate_body:,
        description: 'Test description'
      )
    end
  end

  describe 'usage in Events::Record context' do
    it 'can provide metadata' do
      metadata = described_class.new(
        author:,
        appropriate_body:,
        batch_id: 789,
        batch_type: 'action',
        file_name: 'test.csv',
        file_size: '1024',
        rows: 10,
        mentor_id: 123,
        mentee_id: 456
      )

      result = metadata.to_h

      expect(result[:batch_id]).to eq(789)
      expect(result[:batch_type]).to eq('action')
      expect(result[:file_name]).to eq('test.csv')
      expect(result[:file_size]).to eq('1024')
      expect(result[:rows]).to eq(10)
      expect(result[:mentor_id]).to eq(123)
      expect(result[:mentee_id]).to eq(456)
      expect(result[:appropriate_body]).to eq(appropriate_body)
    end
  end
end
