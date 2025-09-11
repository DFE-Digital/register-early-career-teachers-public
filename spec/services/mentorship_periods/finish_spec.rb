describe MentorshipPeriods::Finish do
  include ActiveJob::TestHelper

  subject { described_class.new(mentorship_period:, finished_on:, author:) }

  let(:started_on) { 1.year.ago.to_date }
  let(:existing_dates) { { started_on:, finished_on: nil } }
  let(:finished_on) { 1.week.ago.to_date }
  let(:author) { FactoryBot.build(:school_user, school_urn: ect_at_school_period.school.urn) }
  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, **existing_dates) }
  let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, **existing_dates) }
  let(:mentorship_period) { FactoryBot.create(:mentorship_period, mentor: mentor_at_school_period, mentee: ect_at_school_period, **existing_dates) }

  describe 'initialization' do
    it 'assigns the mentorship_period' do
      expect(subject.mentorship_period).to eql(mentorship_period)
    end

    it 'assigns the finished_on' do
      expect(subject.finished_on).to eql(finished_on)
    end

    it 'assigns the mentor_at_school_period' do
      expect(subject.mentor_at_school_period).to eql(mentor_at_school_period)
    end

    it 'assigns the ect_at_school_period' do
      expect(subject.ect_at_school_period).to eql(ect_at_school_period)
    end
  end

  describe '#finish!' do
    it 'closes the mentorship_period' do
      subject.finish!

      mentorship_period.reload

      expect(mentorship_period.finished_on).to eql(finished_on)
    end

    it 'records an event for the mentor' do
      allow(Events::Record).to receive(:record_teacher_finishes_mentoring_event!).and_call_original

      expect {
        subject.finish!
        perform_enqueued_jobs
      }.to change(Event, :count).by(2)

      mentorship_period.reload

      expect(Events::Record).to have_received(:record_teacher_finishes_mentoring_event!).with(
        hash_including(
          author:,
          mentorship_period:,
          mentor_at_school_period:,
          happened_at: finished_on,
          school: mentor_at_school_period.school,
          mentor: mentor_at_school_period.teacher,
          mentee: ect_at_school_period.teacher
        )
      )
    end

    it 'records an event for the ECT' do
      allow(Events::Record).to receive(:record_teacher_finishes_being_mentored_event!).and_call_original

      expect {
        subject.finish!
        perform_enqueued_jobs
      }.to change(Event, :count).by(2)

      mentorship_period.reload

      expect(Events::Record).to have_received(:record_teacher_finishes_being_mentored_event!).with(
        hash_including(
          author:,
          mentorship_period:,
          ect_at_school_period:,
          happened_at: finished_on,
          school: ect_at_school_period.school,
          mentor: mentor_at_school_period.teacher,
          mentee: ect_at_school_period.teacher
        )
      )
    end
  end
end
