describe MentorAtSchoolPeriods::Finish do
  subject { MentorAtSchoolPeriods::Finish.new(teacher:, finished_on:, author:, reported_by_school_id:) }

  let(:teacher) { FactoryBot.create(:teacher) }
  let(:started_on) { 3.months.ago.to_date }
  let(:finished_on) { Date.current }
  let(:author) { FactoryBot.create(:school_user, school_urn: mentor_at_school_period.school.urn) }
  let(:reported_by_school_id) { nil }

  let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :ongoing, teacher:, started_on:) }
  let!(:training_period) { FactoryBot.create(:training_period, :for_mentor, :ongoing, mentor_at_school_period:, started_on:) }
  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, started_on:, school: mentor_at_school_period.school) }
  let!(:mentorship_period) { FactoryBot.create(:mentorship_period, :ongoing, mentor: mentor_at_school_period, mentee: ect_at_school_period, started_on:) }

  describe "#finish_periods_at_all_schools!" do
    context "when finished_on is already set" do
      let(:training_period) { nil }
      let(:mentorship_period) { nil }

      context "and is earlier" do
        let(:mentor_at_school_period) do
          FactoryBot.create(
            :mentor_at_school_period,
            teacher:,
            started_on:,
            finished_on: finished_on - 1.month
          )
        end

        it "does not overwrite the existing finished_on" do
          expect { subject.finish_periods_at_all_schools! }.not_to(change { mentor_at_school_period.reload.finished_on })
        end
      end

      context "and is the same date" do
        let(:mentor_at_school_period) do
          FactoryBot.create(
            :mentor_at_school_period,
            teacher:,
            started_on:,
            finished_on:
          )
        end

        it "does not rewrite the finished_on date" do
          expect { subject.finish_periods_at_all_schools! }.not_to(change { mentor_at_school_period.reload.finished_on })
        end
      end
    end

    context "when the mentorship period has not started yet" do
      let(:mentorship_start_date) { finished_on + 2.weeks }
      let!(:mentorship_period) do
        FactoryBot.create(
          :mentorship_period,
          mentor: mentor_at_school_period,
          mentee: ect_at_school_period,
          started_on: mentorship_start_date
        )
      end

      it "deletes the mentorship period" do
        expect { subject.finish_periods_at_all_schools! }.to change(MentorshipPeriod, :count).by(-1)
      end

      it "deletes any events associated with the mentorship period" do
        FactoryBot.create(:event, mentorship_period:)
        FactoryBot.create(:event, mentorship_period:)
        other_event = FactoryBot.create(:event)

        expect(Event.where(mentorship_period:).count).to eq(2)

        subject.finish_periods_at_all_schools!

        expect(Event.where(mentorship_period:)).to be_empty
        expect(Event.exists?(other_event.id)).to be true
      end
    end

    context "when the mentor's leaving date is earlier than the ECT's leaving date" do
      subject { MentorAtSchoolPeriods::Finish.new(teacher:, finished_on: mentor_finished_on, author:, reported_by_school_id:) }

      let(:mentor_finished_on) { finished_on + 1.month }
      let(:ect_finished_on) { finished_on + 2.months }

      let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, started_on:, school: mentor_at_school_period.school) }
      let!(:mentorship_period) { FactoryBot.create(:mentorship_period, :ongoing, mentor: mentor_at_school_period, mentee: ect_at_school_period, started_on:) }

      before do
        ect_at_school_period.update_column(:finished_on, ect_finished_on)
      end

      it "sets the mentorship period finished_on to the mentor's earlier leaving date" do
        subject.finish_periods_at_all_schools!

        expect(mentorship_period.reload.finished_on).to eq(mentor_finished_on)
      end
    end

    context "when the ECT is already reported as leaving on an earlier date than the mentor's leaving date" do
      subject { MentorAtSchoolPeriods::Finish.new(teacher:, finished_on: mentor_finished_on, author:, reported_by_school_id:) }

      let(:mentor_finished_on) { finished_on + 2.months }
      let(:ect_finished_on) { finished_on + 1.month }

      let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, started_on:, school: mentor_at_school_period.school) }
      let!(:mentorship_period) { FactoryBot.create(:mentorship_period, :ongoing, mentor: mentor_at_school_period, mentee: ect_at_school_period, started_on:) }

      before do
        ect_at_school_period.update_column(:finished_on, ect_finished_on)
      end

      it "does not raise an error" do
        expect { subject.finish_periods_at_all_schools! }.not_to raise_error
      end

      it "sets the mentorship period finished_on to the ECT's leaving date, not the mentor's" do
        subject.finish_periods_at_all_schools!

        expect(mentorship_period.reload.finished_on).to eq(ect_finished_on)
      end
    end

    it "finishes all the associated periods" do
      expect(training_period.finished_on).to be_nil
      expect(mentorship_period.finished_on).to be_nil
      expect(mentor_at_school_period.finished_on).to be_nil

      subject.finish_periods_at_all_schools!

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

      subject.finish_periods_at_all_schools!
    end

    context "when reported_by_school_id is provided" do
      let(:reported_by_school_id) { mentor_at_school_period.school_id }

      it "stores the reporting school id" do
        subject.finish_periods_at_all_schools!
        expect(mentor_at_school_period.reload.reported_leaving_by_school_id).to eq(reported_by_school_id)
      end
    end

    it "uses MentorshipPeriods::Finish to close mentorship periods" do
      mentorships_finish = double("MentorshipPeriods::Finish", finish!: true)
      allow(MentorshipPeriods::Finish).to receive(:new).with(
        mentorship_period:,
        finished_on:,
        author:
      ).and_return(mentorships_finish)

      subject.finish_periods_at_all_schools!

      expect(mentorships_finish).to have_received(:finish!).once
    end

    it "uses TrainingPeriods::Finish to close training periods" do
      training_periods_finish = double("TrainingPeriods::Finish", finish!: true)
      allow(TrainingPeriods::Finish).to receive(:mentor_training).with(
        training_period:,
        mentor_at_school_period:,
        finished_on:,
        author:
      ).and_return(training_periods_finish)

      subject.finish_periods_at_all_schools!

      expect(training_periods_finish).to have_received(:finish!).once
    end

    context "when there are no ongoing mentor at school periods" do
      subject { MentorAtSchoolPeriods::Finish.new(teacher: teacher_with_no_periods, finished_on:, author:) }

      let(:teacher_with_no_periods) { FactoryBot.create(:teacher) }
      let(:school) { FactoryBot.create(:school) }
      let(:author) { FactoryBot.create(:school_user, school_urn: school.urn) }

      it "does not record any events when there are no ongoing periods to finish" do
        expect(Events::Record).not_to receive(:record_teacher_left_school_as_mentor!)

        subject.finish_periods_at_all_schools!
      end

      it "does not call any finishing services when there are no ongoing periods" do
        expect(MentorshipPeriods::Finish).not_to receive(:new)
        expect(TrainingPeriods::Finish).not_to receive(:mentor_training)

        subject.finish_periods_at_all_schools!
      end
    end

    context "when there are ongoing mentor at school periods at other schools" do
      let(:other_school) { FactoryBot.create(:school) }
      let(:other_mentor_at_school_period) do
        FactoryBot.create(:mentor_at_school_period, :ongoing, teacher:, school: other_school, started_on:)
      end

      let(:other_ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, started_on:, school: other_school) }
      let!(:other_mentorship_period) { FactoryBot.create(:mentorship_period, :ongoing, mentor: other_mentor_at_school_period, mentee: other_ect_at_school_period, started_on:) }

      it "finishes the periods at other schools" do
        subject.finish_periods_at_all_schools!

        expect(mentor_at_school_period.reload.finished_on).not_to be_nil
        expect(other_mentor_at_school_period.reload.finished_on).not_to be_nil
        expect(training_period.reload.finished_on).not_to be_nil
        expect(mentorship_period.reload.finished_on).not_to be_nil
        expect(other_mentorship_period.reload.finished_on).not_to be_nil
      end

      it "records events for each school" do
        expect(Events::Record).to receive(:record_teacher_left_school_as_mentor!).with(
          author:,
          mentor_at_school_period:,
          teacher:,
          school: mentor_at_school_period.school,
          happened_at: finished_on
        ).once

        expect(Events::Record).to receive(:record_teacher_left_school_as_mentor!).with(
          author:,
          mentor_at_school_period: other_mentor_at_school_period,
          teacher:,
          school: other_school,
          happened_at: finished_on
        ).once

        subject.finish_periods_at_all_schools!
      end

      context "when the mentor has already finished at the other school" do
        let(:other_mentor_at_school_period) do
          FactoryBot.create(:mentor_at_school_period, teacher:, school: other_school, started_on:, finished_on: started_on + 1.month)
        end

        let!(:other_mentorship_period) do
          FactoryBot.create(:mentorship_period, mentor: other_mentor_at_school_period, mentee: other_ect_at_school_period, started_on:, finished_on: started_on + 1.month)
        end

        it "does not update the finished_on for the already finished period" do
          subject.finish_periods_at_all_schools!

          expect(other_mentor_at_school_period.reload.finished_on).to eq(started_on + 1.month)
          expect(other_mentorship_period.reload.finished_on).to eq(started_on + 1.month)
        end

        it "finishes the unfinished periods" do
          subject.finish_periods_at_all_schools!

          expect(mentor_at_school_period.reload.finished_on).not_to be_nil
          expect(training_period.reload.finished_on).not_to be_nil
          expect(mentorship_period.reload.finished_on).not_to be_nil
        end
      end
    end
  end

  describe "finish_periods_at_reported_school!" do
    context "when there are ongoing mentor at school periods at other schools" do
      let(:other_school) { FactoryBot.create(:school) }
      let(:other_mentor_at_school_period) do
        FactoryBot.create(:mentor_at_school_period, :ongoing, teacher:, school: other_school, started_on:)
      end

      let(:other_ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, started_on:, school: other_school) }
      let!(:other_mentorship_period) { FactoryBot.create(:mentorship_period, :ongoing, mentor: other_mentor_at_school_period, mentee: other_ect_at_school_period, started_on:) }

      let(:reported_by_school_id) { mentor_at_school_period.school_id }

      it "only finishes the periods at the reported school" do
        subject.finish_periods_at_reported_school!

        expect(mentor_at_school_period.reload.reported_leaving_by_school_id).to eq(reported_by_school_id)
        expect(mentor_at_school_period.finished_on).not_to be_nil
        expect(training_period.reload.finished_on).not_to be_nil
        expect(mentorship_period.reload.finished_on).not_to be_nil

        expect(other_mentor_at_school_period.reload.reported_leaving_by_school_id).to be_nil
        expect(other_mentor_at_school_period.finished_on).to be_nil
        expect(other_mentorship_period.reload.finished_on).to be_nil
      end

      it "only records an event at the reported school" do
        expect(Events::Record).to receive(:record_teacher_left_school_as_mentor!).with(
          author:,
          mentor_at_school_period:,
          teacher:,
          school: mentor_at_school_period.school,
          happened_at: finished_on
        ).once

        subject.finish_periods_at_reported_school!
      end

      context "when the mentor is training at another school" do
        let!(:training_period) { FactoryBot.create(:training_period, :for_mentor, :ongoing, mentor_at_school_period: other_mentor_at_school_period, started_on:) }

        it "does not finish the training period at the other school" do
          subject.finish_periods_at_reported_school!

          expect(training_period.reload.finished_on).to be_nil
        end
      end

      context "when reported_by_school_id is not provided" do
        let(:reported_by_school_id) { nil }

        it "raises an error" do
          expect { subject.finish_periods_at_reported_school! }.to raise_error(ArgumentError, "reported_by_school_id is required to finish periods at reported school")
        end
      end
    end
  end
end
