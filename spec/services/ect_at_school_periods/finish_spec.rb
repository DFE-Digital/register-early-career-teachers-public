describe ECTAtSchoolPeriods::Finish do
  subject { ECTAtSchoolPeriods::Finish.new(ect_at_school_period:, finished_on:, author:, reported_by_school_id:) }

  let(:started_on) { 1.year.ago.to_date }
  let(:original_dates) { { started_on:, finished_on: nil } }
  let(:finished_on) { 1.week.from_now.to_date }
  let(:reported_by_school_id) { nil }
  let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, **original_dates) }
  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, **original_dates) }
  let!(:training_period) { FactoryBot.create(:training_period, **original_dates, ect_at_school_period:) }
  let(:author) { FactoryBot.build(:school_user, school_urn: ect_at_school_period.school.urn) }
  let(:school) { ect_at_school_period.school }
  let(:teacher) { ect_at_school_period.teacher }

  describe "initialization" do
    it "assigns the ect_at_school_period" do
      expect(subject.ect_at_school_period).to eql(ect_at_school_period)
    end

    it "assigns the finished_on" do
      expect(subject.finished_on).to eql(finished_on)
    end
  end

  describe "#finish!" do
    context "when finished_on is already set to an earlier date" do
      let(:existing_finished_on) { 1.month.ago.to_date }
      let(:original_dates) { { started_on:, finished_on: existing_finished_on } }
      let(:finished_on) { Date.current }
      let(:reported_by_school_id) { ect_at_school_period.school_id }

      it "does not overwrite the existing finished_on" do
        expect { subject.finish! }.not_to(change { ect_at_school_period.reload.finished_on })
      end

      it "stores the reporting school id" do
        expect { subject.finish! }.to change { ect_at_school_period.reload.reported_leaving_by_school_id }.to(reported_by_school_id)
      end
    end

    it "closes the ect_at_school_period" do
      subject.finish!

      ect_at_school_period.reload

      expect(ect_at_school_period.finished_on).to eql(finished_on)
    end

    context "when reported_by_school_id is provided" do
      let(:reported_by_school_id) { ect_at_school_period.school_id }

      it "stores the reporting school id" do
        subject.finish!

        expect(ect_at_school_period.reload.reported_leaving_by_school_id).to eq(reported_by_school_id)
      end
    end

    it "records an event" do
      allow(Events::Record).to receive(:record_teacher_left_school_as_ect!).and_return(true)

      subject.finish!

      expect(Events::Record).to have_received(:record_teacher_left_school_as_ect!).once.with(
        hash_including(author:, ect_at_school_period:, school:, teacher:, training_period:, happened_at: finished_on)
      )
    end

    describe "closing mentorship periods" do
      context "when the mentorship period has not started yet" do
        let(:mentorship_start_date) { finished_on + 1.week }
        let!(:mentorship_period) do
          FactoryBot.create(
            :mentorship_period,
            mentee: ect_at_school_period,
            mentor: mentor_at_school_period,
            started_on: mentorship_start_date
          )
        end

        it "deletes the mentorship period" do
          expect { subject.finish! }.to change(MentorshipPeriod, :count).by(-1)
        end

        it "deletes any events associated with the mentorship period" do
          FactoryBot.create(:event, mentorship_period:)
          FactoryBot.create(:event, mentorship_period:)
          other_event = FactoryBot.create(:event)

          expect(Event.where(mentorship_period:).count).to eq(2)

          subject.finish!

          expect(Event.where(mentorship_period:)).to be_empty
          expect(Event.exists?(other_event.id)).to be true
        end
      end

      context "when the mentorship period starts on the finished_on date" do
        let!(:mentorship_period) do
          FactoryBot.create(
            :mentorship_period,
            mentee: ect_at_school_period,
            mentor: mentor_at_school_period,
            started_on: finished_on
          )
        end

        it "deletes the mentorship period" do
          expect { subject.finish! }.to change(MentorshipPeriod, :count).by(-1)
        end
      end

      context "when there is an ongoing mentorship_period" do
        let!(:mentorship_period) do
          FactoryBot.create(
            :mentorship_period,
            mentee: ect_at_school_period,
            mentor: mentor_at_school_period,
            **original_dates
          )
        end

        it "closes the mentorship period" do
          expect(mentorship_period).to be_ongoing
          subject.finish!
          expect(mentorship_period.reload).not_to be_ongoing
        end

        it "uses MentorshipPeriods::Finish to close it" do
          mentorships_finish = double("MentorshipPeriods::Finish", finish!: true)
          allow(MentorshipPeriods::Finish).to receive(:new).with(any_args).and_return(mentorships_finish)

          subject.finish!

          expect(mentorships_finish).to have_received(:finish!).once
        end
      end

      context "when there is a mentorship period that is set to finish before the date the ECT leaves the school" do
        let(:existing_finished_on) { 1.week.ago.to_date }
        let!(:mentorship_period) do
          FactoryBot.create(
            :mentorship_period,
            mentee: ect_at_school_period,
            mentor: mentor_at_school_period,
            started_on:,
            finished_on: existing_finished_on
          )
        end
        let(:finished_on) { 1.week.from_now.to_date }

        it "leaves the mentorship period finished_on untouched" do
          expect(mentorship_period.reload.finished_on).to eql(existing_finished_on)
        end
      end

      context "when there is a mentorship period that is set to finish after the date the ECT leaves the school" do
        let(:existing_finished_on) { 1.week.from_now.to_date }
        let!(:mentorship_period) do
          FactoryBot.create(
            :mentorship_period,
            mentee: ect_at_school_period,
            mentor: mentor_at_school_period,
            started_on:,
            finished_on: existing_finished_on
          )
        end
        let(:finished_on) { 1.week.ago.to_date }

        it "brings the menorship period finished_on forward" do
          subject.finish!
          expect(mentorship_period.reload.finished_on).to eql(finished_on)
        end
      end
    end

    describe "closing training periods" do
      context "when there is an ongoing training period" do
        let!(:training_period) do
          FactoryBot.create(:training_period, ect_at_school_period:, **original_dates)
        end

        it "closes the training period" do
          expect(training_period).to be_ongoing
          subject.finish!
          expect(training_period.reload).not_to be_ongoing
        end

        it "uses TrainingPeriods::Finish to close it" do
          training_periods_finish = double("TrainingPeriods::Finish", finish!: true)
          allow(TrainingPeriods::Finish).to receive(:new).with(any_args).and_return(training_periods_finish)

          subject.finish!

          expect(training_periods_finish).to have_received(:finish!).once
        end
      end

      context "when there is a training period that is set to finish before the date the ECT leaves the school" do
        let(:existing_finished_on) { 1.week.ago.to_date }
        let!(:training_period) do
          FactoryBot.create(
            :training_period,
            ect_at_school_period:,
            started_on:,
            finished_on: existing_finished_on
          )
        end
        let(:finished_on) { 1.week.from_now.to_date }

        it "leaves the training period finished_on untouched" do
          expect(training_period.reload.finished_on).to eql(existing_finished_on)
        end
      end

      context "when there is a training period that is set to finish after the date the ECT leaves the school" do
        let(:existing_finished_on) { 1.week.from_now.to_date }
        let!(:training_period) do
          FactoryBot.create(
            :training_period,
            ect_at_school_period:,
            started_on:,
            finished_on: existing_finished_on
          )
        end
        let(:finished_on) { 1.week.ago.to_date }

        it "brings the training period finished_on forward" do
          subject.finish!
          expect(training_period.reload.finished_on).to eql(finished_on)
        end
      end
    end
  end
end
