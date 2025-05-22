RSpec.describe RegisterECTHelper, type: :helper do
  describe '#formatted_academic_year_range' do
    it 'returns the correct formatted academic year string' do
      expect(formatted_academic_year_range(2024)).to eq('2024 to 2025')
    end
  end
end
