RSpec.describe Teachers::PreviousECTRegistrationDetails do
  describe '#induction_start_date' do
    context 'when the teacher has induction periods' do
      let(:teacher) { FactoryBot.create(:teacher) }
      let(:previous_ect_registration_details) { described_class.new(trn: teacher.trn) }

      before do
        FactoryBot.create(:induction_period, teacher:, started_on: Date.new(2023, 6, 10), finished_on: Date.new(2023, 9, 30))
        FactoryBot.create(:induction_period, teacher:, started_on: Date.new(2023, 10, 1), finished_on: Date.new(2024, 4, 30))
        FactoryBot.create(:induction_period, teacher:, started_on: Date.new(2024, 5, 1), finished_on: Date.new(2024, 6, 30))
      end

      it 'returns the earliest started_on date formatted as GOV.UK date' do
        expect(previous_ect_registration_details.induction_start_date).to eq(Date.new(2023, 6, 10))
      end
    end

    context 'when the teacher has no induction periods' do
      let(:teacher) { FactoryBot.create(:teacher) }
      let(:previous_ect_registration_details) { described_class.new(trn: teacher.trn) }

      it 'returns nil' do
        expect(previous_ect_registration_details.induction_start_date).to be_nil
      end
    end
  end

  describe '#appropriate_body_name' do
    context 'when the teacher has induction periods' do
      let(:teacher) { FactoryBot.create(:teacher) }
      let(:previous_ect_registration_details) { described_class.new(trn: teacher.trn) }

      let!(:older_body) { FactoryBot.create(:appropriate_body, name: 'Older Body') }
      let!(:more_recent_body) { FactoryBot.create(:appropriate_body, name: 'More Recent Body') }

      before do
        FactoryBot.create(:induction_period, teacher:, started_on: Date.new(2023, 6, 10), finished_on: Date.new(2023, 9, 30), appropriate_body: older_body, created_at: 3.months.ago)
        FactoryBot.create(:induction_period, teacher:, started_on: Date.new(2023, 10, 1), finished_on: Date.new(2024, 4, 30), appropriate_body: more_recent_body, created_at: 1.day.ago)
      end

      it 'returns the name of the latest appropriate body by created_at' do
        expect(previous_ect_registration_details.appropriate_body_name).to eq('More Recent Body')
      end
    end

    context 'when the teacher has no induction periods' do
      let(:teacher) { FactoryBot.create(:teacher) }
      let(:previous_ect_registration_details) { described_class.new(trn: teacher.trn) }

      it 'returns nil' do
        expect(previous_ect_registration_details.appropriate_body_name).to be_nil
      end
    end
  end

  describe '#training_programme' do
    let(:teacher) { FactoryBot.create(:teacher) }
    let(:previous_ect_registration_details) { described_class.new(trn: teacher.trn) }

    context 'when the teacher has ECTAtSchoolPeriods' do
      before do
        FactoryBot.create(:ect_at_school_period, teacher:, programme_type: :school_led, created_at: 2.days.ago, lead_provider_id: nil)
        FactoryBot.create(:ect_at_school_period, teacher:, programme_type: :provider_led, created_at: 1.day.ago)
      end

      it 'returns the programme type from the latest ECTAtSchoolPeriod' do
        expect(previous_ect_registration_details.training_programme).to eq('provider_led')
      end
    end

    context 'when the teacher has no ECTAtSchoolPeriods' do
      it 'returns nil' do
        expect(previous_ect_registration_details.training_programme).to be_nil
      end
    end
  end

  describe '#provider_led?' do
    let(:teacher) { FactoryBot.create(:teacher) }
    let(:service) { described_class.new(trn: teacher.trn) }

    it 'returns true when the latest ECTAtSchoolPeriod is provider-led' do
      FactoryBot.create(:ect_at_school_period, teacher:, programme_type: :provider_led)
      expect(service.provider_led?).to be(true)
    end

    it 'returns false when the latest ECTAtSchoolPeriod is school-led' do
      FactoryBot.create(:ect_at_school_period, teacher:, programme_type: :school_led, lead_provider_id: nil)
      expect(service.provider_led?).to be(false)
    end

    it 'returns nil when there are no ECTAtSchoolPeriods' do
      expect(service.provider_led?).to be_nil
    end
  end

  describe '#lead_provider_name' do
    let(:teacher) { FactoryBot.create(:teacher) }
    let(:service) { described_class.new(trn: teacher.trn) }
    let(:lead_provider) { FactoryBot.create(:lead_provider, name: 'Confirmed LP') }

    before do
      ect_period = FactoryBot.create(
        :ect_at_school_period,
        teacher:,
        started_on: Date.new(2023, 12, 25),
        finished_on: Date.new(2024, 12, 25)
      )

      FactoryBot.create(
        :training_period,
        ect_at_school_period: ect_period,
        school_partnership: FactoryBot.create(:school_partnership, lead_provider:),
        started_on: Date.new(2023, 12, 26),
        finished_on: Date.new(2024, 12, 24)
      )
    end

    it 'returns the name of the lead provider from the latest training period' do
      expect(service.lead_provider_name).to eq('Confirmed LP')
    end
  end

  describe '#delivery_partner_name' do
    let(:teacher) { FactoryBot.create(:teacher) }
    let(:service) { described_class.new(trn: teacher.trn) }
    let(:delivery_partner) { FactoryBot.create(:delivery_partner, name: 'DP') }

    before do
      ect_period = FactoryBot.create(
        :ect_at_school_period,
        teacher:,
        started_on: Date.new(2023, 12, 25),
        finished_on: Date.new(2024, 12, 25)
      )

      FactoryBot.create(
        :training_period,
        ect_at_school_period: ect_period,
        delivery_partner:,
        started_on: Date.new(2023, 12, 26),
        finished_on: Date.new(2024, 12, 24)
      )
    end

    it 'returns the name of the delivery partner from the latest training period' do
      expect(service.delivery_partner_name).to eq("DP")
    end
  end
end
