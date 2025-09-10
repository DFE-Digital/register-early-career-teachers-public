describe MentorAtSchoolPeriods::Finish do
  subject { MentorAtSchoolPeriods::Finish.new(teacher:, finished_on:, author:) }

  let(:teacher) { FactoryBot.create(:teacher) }
  let(:started_on) { 3.months.ago.to_date }
  let(:finished_on) { Date.current }
  let(:author) { FactoryBot.create(:school_user, school_urn: mentor_at_school_period.school.urn) }

  let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :ongoing, teacher:, started_on:) }
  let!(:training_period) { FactoryBot.create(:training_period, :for_mentor, :ongoing, mentor_at_school_period:, started_on:) }
  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, started_on:) }
  let!(:mentorship_period) { FactoryBot.create(:mentorship_period, :ongoing, mentor: mentor_at_school_period, mentee: ect_at_school_period, started_on:) }

  describe '#finish_existing_at_school_periods!' do
    it "finishes all the associated periods" do
      expect(training_period.finished_on).to be_nil
      expect(mentorship_period.finished_on).to be_nil
      expect(mentor_at_school_period.finished_on).to be_nil

      subject.finish_existing_at_school_periods!

      expect(training_period.reload.finished_on).not_to be_nil
      expect(mentorship_period.reload.finished_on).not_to be_nil
      expect(mentor_at_school_period.reload.finished_on).not_to be_nil
    end

    it "records an event for closing down the mentor at school period" do
      expect(Events::Record).to receive(:record_teacher_left_school_as_mentor!).with(
        author:,
        mentor_at_school_period:,
        teacher:,
        school: mentor_at_school_period.school,
        happened_at: finished_on
      )

      subject.finish_existing_at_school_periods!
    end

    it "uses MentorshipPeriods::Finish to close mentorship periods" do
      mentorships_finish = double('MentorshipPeriods::Finish', finish!: true)
      allow(MentorshipPeriods::Finish).to receive(:new).with(
        mentorship_period:,
        finished_on:,
        author:
      ).and_return(mentorships_finish)

      subject.finish_existing_at_school_periods!

      expect(mentorships_finish).to have_received(:finish!).once
    end

    it "uses TrainingPeriods::Finish to close training periods" do
      training_periods_finish = double('TrainingPeriods::Finish', finish!: true)
      allow(TrainingPeriods::Finish).to receive(:mentor_training).with(
        training_period:,
        mentor_at_school_period:,
        finished_on:,
        author:
      ).and_return(training_periods_finish)

      subject.finish_existing_at_school_periods!

      expect(training_periods_finish).to have_received(:finish!).once
    end

    context 'when there are no ongoing mentor at school periods' do
      subject { MentorAtSchoolPeriods::Finish.new(teacher: teacher_with_no_periods, finished_on:, author:) }

      let(:teacher_with_no_periods) { FactoryBot.create(:teacher) }
      let(:school) { FactoryBot.create(:school) }
      let(:author) { FactoryBot.create(:school_user, school_urn: school.urn) }

      it 'does not record any events when there are no ongoing periods to finish' do
        expect(Events::Record).not_to receive(:record_teacher_left_school_as_mentor!)

        subject.finish_existing_at_school_periods!
      end

      it 'does not call any finishing services when there are no ongoing periods' do
        expect(MentorshipPeriods::Finish).not_to receive(:new)
        expect(TrainingPeriods::Finish).not_to receive(:mentor_training)

        subject.finish_existing_at_school_periods!
      end
    end
  end
end
