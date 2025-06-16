RSpec.describe ProgrammeHelper, type: :helper do
  describe '#training_programme_name' do
    context "for 'provider_led'" do
      it { expect(training_programme_name('provider_led')).to eq('Provider-led') }
    end

    context "for 'school_led'" do
      it { expect(training_programme_name('school_led')).to eq('School-led') }
    end
  end

  describe '#previous_choice_message' do
    context 'when use_previous_ect_choices is true' do
      it { expect(previous_choice_message(true)).to eq("Yes, use the programme choices used by my school previously") }
    end

    context 'when use_previous_ect_choices is false' do
      it { expect(previous_choice_message(false)).to eq("No, don't use the programme choices used by my school previously") }
    end
  end
end
