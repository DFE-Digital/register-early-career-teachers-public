describe MentorAtSchoolPeriods::LatestRegistrationChoices do
  subject { MentorAtSchoolPeriods::LatestRegistrationChoices.new(trn: teacher.trn) }

  let(:teacher) { FactoryBot.create(:teacher) }
  let(:school_partnership) { FactoryBot.create(:school_partnership) }
  let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, teacher:) }
  let!(:training_period) { FactoryBot.create(:training_period, :for_mentor, :ongoing, school_partnership:, started_on: mentor_at_school_period.started_on, mentor_at_school_period:) }

  describe '#school' do
    it { expect(subject.school).to eq(school_partnership.school) }
  end

  describe '#lead_provider' do
    it { expect(subject.lead_provider).to eq(school_partnership.lead_provider) }
  end

  describe '#delivery_partner' do
    it { expect(subject.delivery_partner).to eq(school_partnership.delivery_partner) }
  end
end
