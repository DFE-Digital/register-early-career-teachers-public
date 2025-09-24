RSpec.describe MentorAtSchoolPeriods::Eligibility, type: :service do
  describe '.for_first_provider_led_training?' do
    let(:school) { FactoryBot.create(:school) }
    let(:teacher) { FactoryBot.create(:teacher) }
    let(:result) do
      described_class.for_first_provider_led_training?(
        mentor_at_school_period:,
        ect_at_school_period:
      )
    end

    context 'when mentor is eligible for funding, ECT is provider-led, and the mentor has no ongoing training periods' do
      let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :ongoing, school:, teacher:) }
      let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, school:) }

      before { FactoryBot.create(:training_period, :for_ect, :ongoing, :provider_led, ect_at_school_period:) }

      it 'returns true' do
        expect(result).to be(true)
      end
    end

    context 'when mentor already has an ongoing training period' do
      let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :ongoing, school:, teacher:) }
      let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, school:) }

      before do
        FactoryBot.create(:training_period, :for_ect, :ongoing, :provider_led, ect_at_school_period:)
        FactoryBot.create(:training_period, :for_mentor, :ongoing, :provider_led, mentor_at_school_period:)
      end

      it 'returns false' do
        expect(result).to be(false)
      end
    end

    context 'when mentor is ineligible for funding' do
      let(:teacher) { FactoryBot.create(:teacher, :ineligible_for_mentor_funding) }
      let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :ongoing, school:, teacher:) }
      let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, school:) }

      before { FactoryBot.create(:training_period, :for_ect, :ongoing, :provider_led, ect_at_school_period:) }

      it 'returns false' do
        expect(result).to be(false)
      end
    end

    context 'when ECT is school-led' do
      let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :ongoing, school:, teacher:) }
      let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, school:) }

      before { FactoryBot.create(:training_period, :for_ect, :ongoing, :school_led, ect_at_school_period:) }

      it 'returns false' do
        expect(result).to be(false)
      end
    end

    context 'when mentor_at_school_period is nil' do
      let(:mentor_at_school_period) { nil }
      let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, school:) }

      it 'returns false' do
        expect(result).to be(false)
      end
    end

    context 'when ect_at_school_period is nil' do
      let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :ongoing, school:, teacher:) }
      let(:ect_at_school_period) { nil }

      it 'returns false' do
        expect(result).to be(false)
      end
    end
  end
end
