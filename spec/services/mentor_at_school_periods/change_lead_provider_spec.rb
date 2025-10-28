RSpec.describe MentorAtSchoolPeriods::ChangeLeadProvider, type: :service do
  subject { described_class.new(mentor_at_school_period:, school_partnership:, author:) }

  let(:teacher) { FactoryBot.create(:teacher) }
  let(:started_on) { 3.months.ago.to_date }
  let(:author) { FactoryBot.create(:school_user, school_urn: mentor_at_school_period.school.urn) }

  let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :ongoing, teacher:, started_on:) }
  let!(:training_period) { FactoryBot.create(:training_period, :for_mentor, :ongoing, mentor_at_school_period:, started_on:) }
  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, started_on:) }
  let!(:mentorship_period) { FactoryBot.create(:mentorship_period, :ongoing, mentor: mentor_at_school_period, mentee: ect_at_school_period, started_on:) }

  let(:old_lead_provider) { training_period.lead_provider }
  let(:new_lead_provider) { school_partnership.lead_provider }
  let(:school_partnership) { FactoryBot.create(:school_partnership) }
  let(:training_programme) { 'provider_led' }

  describe '#call' do
    context 'when there are existing training periods' do
      it 'closes existing training periods and opens a new training period' do
        expect { subject.call }.to change(TrainingPeriod, :count).by(1)

        expect(training_period.reload.finished_on).to eq(Time.zone.today)
        expect(mentorship_period.reload.finished_on).to eq(Time.zone.today)
      end
    end

    context 'when there are no existing training periods' do
      let(:training_period) { nil }

      it 'opens a new training period' do
        expect { subject.call }.to change(TrainingPeriod, :count).by(1)
      end
    end

    context 'when the existing training period is already finished' do
      let!(:training_period) { FactoryBot.create(:training_period, :for_mentor, :finished, mentor_at_school_period:, started_on:) }

      it 'opens a new training period' do
        expect { subject.call }.to change(TrainingPeriod, :count).by(1)
      end
    end

    context 'when a relationship already exists with this lead provider' do
      it 'opens a new training period with the new lead provider' do
        subject.call

        new_training_period = mentor_at_school_period.training_periods.ongoing.first
        expect(new_training_period.lead_provider).to eq(new_lead_provider)
        expect(new_training_period.started_on).to eq(Time.zone.today + 1)
        expect(new_training_period.training_programme).to eq('provider_led')
      end
    end

    xcontext 'when no relationship exists with this lead provider' do
      xit 'creates a new expression of interest' do
      end
    end

    xit 'writes an appropriate event' do
    end
  end
end
