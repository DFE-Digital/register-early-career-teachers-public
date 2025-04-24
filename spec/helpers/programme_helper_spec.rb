RSpec.describe ProgrammeHelper, type: :helper do
  describe '#programme_type_name' do
    context "for 'provider_led'" do
      it { expect(programme_type_name('provider_led')).to eq('Provider-led') }
    end

    context "for 'school_led'" do
      it { expect(programme_type_name('school_led')).to eq('School-led') }
    end
  end

  describe '#programme_choices' do
    context 'when use_previous_ect_choices is true' do
      it { expect(programme_choices(true)).to eq("Yes, use the programme choices used by my school previously") }
    end

    context 'when use_previous_ect_choices is false' do
      it { expect(programme_choices(false)).to eq("No, don't use the programme choices used by my school previously") }
    end
  end
end
