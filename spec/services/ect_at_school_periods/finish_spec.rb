describe ECTAtSchoolPeriods::Finish do
  subject { ECTAtSchoolPeriods::Finish.new(ect_at_school_period:, finished_on:, author:) }

  let(:finished_on) { 1.week.from_now.to_date }
  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing) }
  let!(:training_period) { FactoryBot.create(:training_period, :ongoing, ect_at_school_period:) }
  let(:author) { FactoryBot.build(:school_user, school_urn: ect_at_school_period.school.urn) }
  let(:school) { ect_at_school_period.school }
  let(:teacher) { ect_at_school_period.teacher }

  describe 'initialization' do
    it 'assigns the ect_at_school_period' do
      expect(subject.ect_at_school_period).to eql(ect_at_school_period)
    end

    it 'assigns the finished_on' do
      expect(subject.finished_on).to eql(finished_on)
    end
  end

  describe '#finish!' do
    it 'closes the ect_at_school_period' do
      subject.finish!

      ect_at_school_period.reload

      expect(ect_at_school_period.finished_on).to eql(finished_on)
    end

    it 'records an event' do
      allow(Events::Record).to receive(:record_teacher_left_school_as_ect!).and_return(true)

      subject.finish!

      expect(Events::Record).to have_received(:record_teacher_left_school_as_ect!).once.with(
        hash_including(author:, ect_at_school_period:, school:, teacher:, training_period:, happened_at: finished_on)
      )
    end

    it 'closes the ongoing training_period if there is one'
    it 'closes the ongoing mentorship_period if there is one'
  end
end
