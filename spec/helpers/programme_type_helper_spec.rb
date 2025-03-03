RSpec.describe ProgrammeTypeHelper, type: :helper do
  describe '#programme_type_name' do
    context "for 'provider_led'" do
      it { expect(programme_type_name('provider_led')).to eq('Provider-led') }
    end

    context "for 'school_led'" do
      it { expect(programme_type_name('school_led')).to eq('School-led') }
    end
  end
end
