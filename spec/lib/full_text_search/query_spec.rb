describe FullTextSearch::Query do
  subject { FullTextSearch::Query.new(string).search_by_all_prefixes }

  context 'when the string has no words' do
    let(:string) { '' }

    it { is_expected.to be_empty }
  end

  context 'when the string has one word (Cletus)' do
    let(:string) { 'Cletus' }

    it { is_expected.to eql('Cletus:*') }
  end

  context 'when the string has many words (Cletus Van Damme)' do
    let(:string) { 'Cletus Van Damme' }

    it { is_expected.to eql('Cletus:* & Van:* & Damme:*') }
  end
end
