RSpec.describe ProgrammeHelper, type: :helper do
  describe '#programme_type_name' do
    context "for 'provider_led'" do
      it { expect(programme_type_name('provider_led')).to eq('Provider-led') }
    end

    context "for 'school_led'" do
      it { expect(programme_type_name('school_led')).to eq('School-led') }
    end
  end

  describe '#training_programme_for' do
    let(:teacher) { FactoryBot.create(:teacher) }

    before do
      FactoryBot.create(:ect_at_school_period, teacher:, programme_type: :school_led, created_at: 2.days.ago, lead_provider_id: nil)
      FactoryBot.create(:ect_at_school_period, teacher:, programme_type: :provider_led, created_at: 1.day.ago)
    end

    it 'returns the programme name from the latest ECTAtSchoolPeriod' do
      expect(helper.training_programme_for(teacher.trn)).to eq('Provider-led')
    end

    it 'returns nil if no periods exist' do
      expect(helper.training_programme_for('1234567')).to be_nil
    end
  end
end
