describe 'TrainingPeriods::Finish' do
  include ActiveJob::TestHelper

  let(:finished_on) { Date.yesterday.to_date }

  describe '.ect_training' do
    subject { TrainingPeriods::Finish.ect_training(training_period:, finished_on:, author:, ect_at_school_period:) }

    let(:author) { FactoryBot.build(:school_user, school_urn: ect_at_school_period.school.urn) }
    let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing) }
    let(:training_period) { FactoryBot.create(:training_period, :for_ect, :ongoing, ect_at_school_period:) }

    it 'assigns the training_period' do
      expect(subject.training_period).to eql(training_period)
    end

    it 'assigns the finished_on' do
      expect(subject.finished_on).to eql(finished_on)
    end

    it 'assigns the ect_at_school_period' do
      expect(subject.ect_at_school_period).to eql(ect_at_school_period)
    end

    it 'sets the mentor_at_school_period to nil' do
      expect(subject.mentor_at_school_period).to be_nil
    end

    it 'sets the teacher' do
      expect(subject.teacher).to eql(ect_at_school_period.teacher)
    end
  end

  describe '.mentor_training' do
    subject { TrainingPeriods::Finish.mentor_training(training_period:, finished_on:, author:, mentor_at_school_period:) }

    let(:author) { FactoryBot.build(:school_user, school_urn: mentor_at_school_period.school.urn) }
    let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :ongoing) }
    let(:training_period) { FactoryBot.create(:training_period, :for_mentor, :ongoing, mentor_at_school_period:) }

    it 'assigns the training_period' do
      expect(subject.training_period).to eql(training_period)
    end

    it 'assigns the finished_on' do
      expect(subject.finished_on).to eql(finished_on)
    end

    it 'assigns the mentor_at_school_period' do
      expect(subject.mentor_at_school_period).to eql(mentor_at_school_period)
    end

    it 'sets the ect_at_school_period to nil' do
      expect(subject.ect_at_school_period).to be_nil
    end

    it 'sets the teacher' do
      expect(subject.teacher).to eql(mentor_at_school_period.teacher)
    end
  end

  describe '#finish!' do
    let(:started_on) { Date.new(2024, 1, 1) }
    let(:date_params) { { started_on:, finished_on: nil } }

    context 'when ECT' do
      subject { TrainingPeriods::Finish.ect_training(training_period:, finished_on:, author:, ect_at_school_period:) }

      let(:author) { FactoryBot.build(:school_user, school_urn: ect_at_school_period.school.urn) }
      let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, **date_params) }
      let(:training_period) { FactoryBot.create(:training_period, :for_ect, ect_at_school_period:, **date_params) }

      it 'closes the training_period' do
        subject.finish!

        training_period.reload

        expect(training_period.finished_on).to eql(finished_on)
      end

      it 'records an event' do
        allow(Events::Record).to receive(:record_teacher_finishes_training_period_event!).and_call_original

        expect {
          subject.finish!
          perform_enqueued_jobs
        }.to change(Event, :count).by(1)

        training_period.reload

        expect(Events::Record).to have_received(:record_teacher_finishes_training_period_event!).with(
          hash_including(
            author:,
            training_period:,
            ect_at_school_period:,
            happened_at: finished_on,
            school: ect_at_school_period.school
          )
        )
      end
    end

    context 'when mentor' do
      subject { TrainingPeriods::Finish.mentor_training(training_period:, finished_on:, author:, mentor_at_school_period:) }

      let(:author) { FactoryBot.build(:school_user, school_urn: mentor_at_school_period.school.urn) }
      let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, **date_params) }
      let(:training_period) { FactoryBot.create(:training_period, :for_mentor, mentor_at_school_period:, **date_params) }

      it 'closes the training_period' do
        subject.finish!

        training_period.reload

        expect(training_period.finished_on).to eql(finished_on)
      end

      it 'records an event' do
        allow(Events::Record).to receive(:record_teacher_finishes_training_period_event!).and_call_original

        expect {
          subject.finish!
          perform_enqueued_jobs
        }.to change(Event, :count).by(1)

        training_period.reload

        expect(Events::Record).to have_received(:record_teacher_finishes_training_period_event!).with(
          hash_including(
            author:,
            training_period:,
            mentor_at_school_period:,
            happened_at: finished_on,
            school: mentor_at_school_period.school
          )
        )
      end
    end
  end
end
