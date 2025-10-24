Rspec.describe MentorAtSchoolPeriods::ChangeLeadProvider, type: :service do
  describe '#call' do
    let(:school) { FactoryBot.create(:school) }
    let(:teacher) { FactoryBot.create(:teacher) }
    let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :ongoing, school:, teacher:) }
    let(:old_lead_provider) { FactoryBot.create(:lead_provider) }
    let(:new_lead_provider) { FactoryBot.create(:lead_provider) }
    let(:service) { described_class.new(mentor_at_school_period, new_lead_provider) }
    let!(:existing_training_period) do
      FactoryBot.create(:training_period, :for_mentor, :ongoing, lead_provider: old_lead_provider, mentor_at_school_period:)
    end

    it 'closes the existing training period and opens a new one with the new lead provider' do
      service.call

      closed_training_period = mentor_at_school_period.training_periods.find_by(lead_provider: old_lead_provider)
      new_training_period = mentor_at_school_period.training_periods.find_by(lead_provider: new_lead_provider)

      expect(closed_training_period).not_to be_nil
      expect(closed_training_period.end_date).not_to be_nil
      expect(new_training_period).not_to be_nil
      expect(new_training_period.start_date).to eq(Date.today)
      expect(new_training_period.end_date).to be_nil
    end

    it 'opens a new training period with the new lead provider' do
    end

    it 'writes an appropriate event' do
    end

    context 'when there are no existing training periods' do
      let(:existing_training_period) { nil }

      it 'works' do
      end
    end

    context 'when the existing training period is already closed' do
      let!(:existing_training_period) do
        FactoryBot.create(:training_period, :for_mentor, :closed, lead_provider: old_lead_provider, mentor_at_school_period:)
      end

      it 'works' do
      end
    end
  end
end
