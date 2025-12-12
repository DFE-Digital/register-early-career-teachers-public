RSpec.describe Schools::AssignMentor do
  subject(:service) do
    described_class.new(author:, ect: mentee, mentor: new_mentor)
  end

  let(:mentee_started_on) { 3.years.ago }
  let(:mentor_started_on) { 3.years.ago }
  let(:new_mentor_started_on) { 3.years.ago.to_date }

  let(:mentee) { FactoryBot.create(:ect_at_school_period, :ongoing, started_on: mentee_started_on) }
  let(:new_mentor) { FactoryBot.create(:mentor_at_school_period, :ongoing, started_on: new_mentor_started_on, school: mentee.school) }
  let(:author) { FactoryBot.create(:school_user, school_urn: mentee.school.urn) }

  describe "#assign!" do
    context "when the new mentor is moving schools" do
      let(:previous_school) { FactoryBot.create(:school) }

      before do
        FactoryBot.create(:mentor_at_school_period, :ongoing, school: previous_school, teacher: new_mentor.teacher)
      end

      context "when there is a mentorship period" do
        let(:current_mentor) { FactoryBot.create(:mentor_at_school_period, :ongoing, started_on: mentor_started_on) }
        let!(:current_mentorship) { FactoryBot.create(:mentorship_period, :ongoing, mentee:, mentor: current_mentor, started_on: mentorship_period_started_on) }

        context "current mentorship starts in the future" do
          let(:mentorship_period_started_on) { new_mentor_started_on + 1.day }

          it "deletes any events associated with the old mentorship period" do
            FactoryBot.create(:event, mentorship_period: current_mentorship)
            FactoryBot.create(:event, mentorship_period: current_mentorship)
            FactoryBot.create(:event)

            expect(Event.all.count).to eq(3)
            service.assign!

            expect(Event.where(mentorship_period: current_mentorship)).to be_empty
            expect(Event.all.count).to eq(1)
          end

          it "deletes the old mentorship period" do
            service.assign!

            expect { current_mentorship.reload }.to raise_error(ActiveRecord::RecordNotFound)
          end

          it "creates a new one starting on the new mentor's start date" do
            expect(ECTAtSchoolPeriods::Mentorship.new(mentee).current_mentor).to eq(current_mentor)
            expect(MentorshipPeriod.count).to eq(1)

            expect { service.assign! }.not_to change(MentorshipPeriod, :count)
            expect(ECTAtSchoolPeriods::Mentorship.new(mentee.reload).current_mentor).to eq(new_mentor)
            expect(ECTAtSchoolPeriods::Mentorship.new(mentee).current_or_next_mentorship_period.started_on).to eq(new_mentor_started_on)
          end
        end

        context "current mentorship starts today" do
          let(:mentorship_period_started_on) { new_mentor_started_on }

          it "deletes any events associated with the old mentorship period" do
            FactoryBot.create(:event, mentorship_period: current_mentorship)
            FactoryBot.create(:event, mentorship_period: current_mentorship)
            FactoryBot.create(:event)

            expect(Event.all.count).to eq(3)
            service.assign!

            expect(Event.where(mentorship_period: current_mentorship)).to be_empty
            expect(Event.all.count).to eq(1)
          end

          it "deletes the old mentorship period" do
            service.assign!

            expect { current_mentorship.reload }.to raise_error(ActiveRecord::RecordNotFound)
          end

          it "creates a new one starting on the new mentor's start date" do
            expect(ECTAtSchoolPeriods::Mentorship.new(mentee).current_mentor).to eq(current_mentor)
            expect(MentorshipPeriod.count).to eq(1)

            expect { service.assign! }.not_to change(MentorshipPeriod, :count)
            expect(ECTAtSchoolPeriods::Mentorship.new(mentee.reload).current_mentor).to eq(new_mentor)
            expect(ECTAtSchoolPeriods::Mentorship.new(mentee).current_or_next_mentorship_period.started_on).to eq(new_mentor_started_on)
          end
        end

        context "current mentorship has started" do
          let(:mentee_started_on) { new_mentor_started_on - 1.day }
          let(:mentor_started_on) { new_mentor_started_on - 1.day }
          let(:mentorship_period_started_on) { mentor_started_on }

          it "does not delete any events associated with the old mentorship period" do
            allow(Event).to receive(:delete_all).and_call_original
            FactoryBot.create(:event, mentorship_period: current_mentorship)
            FactoryBot.create(:event, mentorship_period: current_mentorship)

            service.assign!

            expect(Event).not_to have_received(:delete_all)
            expect(Event.where(mentorship_period: current_mentorship).count).to eq(2)
          end

          it "finishes the current mentorship period" do
            expect { service.assign! }.to change { current_mentorship.reload.finished_on }.from(nil).to(new_mentor_started_on)
          end

          it "creates a new one starting on the new mentor's start date" do
            expect(ECTAtSchoolPeriods::Mentorship.new(mentee).current_mentor).to eq(current_mentor)
            expect { service.assign! }.to change(MentorshipPeriod, :count).from(1).to(2)
            expect(ECTAtSchoolPeriods::Mentorship.new(mentee.reload).current_mentor).to eq(new_mentor)
            expect(ECTAtSchoolPeriods::Mentorship.new(mentee).current_or_next_mentorship_period.started_on).to eq(new_mentor_started_on + 1.day)
          end
        end
      end

      context "when there is no mentorship period" do
        it "does not delete any events" do
          allow(Event).to receive(:delete_all).and_call_original
          service.assign!

          expect(Event).not_to have_received(:delete_all)
        end

        it "creates a new mentorship period starting on the new mentor's start date" do
          expect { service.assign! }.to change(MentorshipPeriod, :count).from(0).to(1)
          expect(ECTAtSchoolPeriods::Mentorship.new(mentee.reload).current_mentor).to eq(new_mentor)
          expect(ECTAtSchoolPeriods::Mentorship.new(mentee).current_or_next_mentorship_period.started_on).to eq(new_mentor_started_on)
        end
      end
    end

    context "when the new mentor is not moving schools" do
      context "when there is a mentorship period" do
        let(:current_mentor) { FactoryBot.create(:mentor_at_school_period, :ongoing, started_on: mentor_started_on) }
        let!(:current_mentorship) { FactoryBot.create(:mentorship_period, :ongoing, mentee:, mentor: current_mentor, started_on: mentorship_period_started_on) }

        context "current mentorship starts in the future" do
          let(:mentorship_period_started_on) { new_mentor_started_on + 1.day }

          it "does not delete any events associated with the old mentorship period" do
            allow(Event).to receive(:delete_all).and_call_original
            FactoryBot.create(:event, mentorship_period: current_mentorship)
            FactoryBot.create(:event, mentorship_period: current_mentorship)

            service.assign!

            expect(Event).not_to have_received(:delete_all)
            expect(Event.where(mentorship_period: current_mentorship).count).to eq(2)
          end

          it "ends current mentorship of the ect" do
            expect { service.assign! }.to change { current_mentorship.reload.finished_on }.from(nil).to(Date.current)
          end

          it "adds a new mentorship for the ect with the new mentor starting tomorrow" do
            expect(ECTAtSchoolPeriods::Mentorship.new(mentee).current_mentor).to eq(current_mentor)
            expect { service.assign! }.to change(MentorshipPeriod, :count).from(1).to(2)
            expect(ECTAtSchoolPeriods::Mentorship.new(mentee.reload).current_mentor).to eq(new_mentor)
            expect(ECTAtSchoolPeriods::Mentorship.new(mentee).current_or_next_mentorship_period.started_on).to eq(Date.tomorrow)
          end
        end

        context "current mentorship starts today" do
          let(:mentorship_period_started_on) { new_mentor_started_on }

          it "ends current mentorship of the ect" do
            expect { service.assign! }.to change { current_mentorship.reload.finished_on }.from(nil).to(Date.current)
          end

          it "adds a new mentorship for the ect with the new mentor starting tomorrow" do
            expect(ECTAtSchoolPeriods::Mentorship.new(mentee).current_mentor).to eq(current_mentor)
            expect { service.assign! }.to change(MentorshipPeriod, :count).from(1).to(2)
            expect(ECTAtSchoolPeriods::Mentorship.new(mentee.reload).current_mentor).to eq(new_mentor)
            expect(ECTAtSchoolPeriods::Mentorship.new(mentee).current_or_next_mentorship_period.started_on).to eq(Date.tomorrow)
          end
        end

        context "current mentorship has started" do
          let(:mentee_started_on) { new_mentor_started_on - 1.day }
          let(:mentor_started_on) { new_mentor_started_on - 1.day }
          let(:mentorship_period_started_on) { mentor_started_on }

          it "finishes the current mentorship period" do
            expect { service.assign! }.to change { current_mentorship.reload.finished_on }.from(nil).to(Date.current)
          end

          it "adds a new mentorship for the ect with the new mentor starting tomorrow" do
            expect(ECTAtSchoolPeriods::Mentorship.new(mentee).current_mentor).to eq(current_mentor)
            expect { service.assign! }.to change(MentorshipPeriod, :count).from(1).to(2)
            expect(ECTAtSchoolPeriods::Mentorship.new(mentee.reload).current_mentor).to eq(new_mentor)
            expect(ECTAtSchoolPeriods::Mentorship.new(mentee).current_or_next_mentorship_period.started_on).to eq(Date.tomorrow)
          end
        end
      end

      context "when there is no mentorship period" do
        it "does not delete any events" do
          allow(Event).to receive(:delete_all).and_call_original
          service.assign!

          expect(Event).not_to have_received(:delete_all)
        end

        it "creates a new mentorship period starting on the new mentor's start date" do
          expect { service.assign! }.to change(MentorshipPeriod, :count).from(0).to(1)
          expect(ECTAtSchoolPeriods::Mentorship.new(mentee.reload).current_mentor).to eq(new_mentor)
          expect(ECTAtSchoolPeriods::Mentorship.new(mentee).current_or_next_mentorship_period.started_on).to eq(Date.current)
        end
      end
    end

    describe "future dates" do
      context "when the mentee (ECT) start date is in the future" do
        let(:mentee_started_on) { 3.weeks.from_now.to_date }

        it "sets the start date to the mentee start date" do
          service.assign!

          expect(service.mentorship_period.started_on).to eq(mentee_started_on)
        end
      end

      context "when the mentor start date is in the future" do
        let(:new_mentor_started_on) { 1.month.from_now.to_date }

        it "sets the start date to the mentor start date" do
          service.assign!

          expect(service.mentorship_period.started_on).to eq(new_mentor_started_on)
        end
      end
    end

    describe "latest_possible_finish" do
      context "when neither ECT nor mentor are scheduled to leave" do
        it "sets finished_on to nil" do
          service.assign!

          expect(service.mentorship_period.finished_on).to be_nil
        end
      end

      context "when only the ECT is scheduled to leave" do
        let(:ect_finish_date) { 2.months.from_now.to_date }
        let(:mentee) { FactoryBot.create(:ect_at_school_period, started_on: mentee_started_on, finished_on: ect_finish_date) }

        it "sets finished_on to the ECT finish date" do
          service.assign!

          expect(service.mentorship_period.finished_on).to eq(ect_finish_date)
        end
      end

      context "when only the mentor is scheduled to leave" do
        let(:mentor_finish_date) { 3.months.from_now.to_date }
        let(:new_mentor) { FactoryBot.create(:mentor_at_school_period, started_on: mentor_started_on, finished_on: mentor_finish_date) }

        it "sets finished_on to the mentor finish date" do
          service.assign!

          expect(service.mentorship_period.finished_on).to eq(mentor_finish_date)
        end
      end

      context "when both ECT and mentor are scheduled to leave" do
        let(:ect_finish_date) { 2.months.from_now.to_date }
        let(:mentor_finish_date) { 3.months.from_now.to_date }
        let(:mentee) { FactoryBot.create(:ect_at_school_period, started_on: mentee_started_on, finished_on: ect_finish_date) }
        let(:new_mentor) { FactoryBot.create(:mentor_at_school_period, started_on: mentor_started_on, finished_on: mentor_finish_date) }

        it "sets finished_on to the earliest finish date" do
          service.assign!

          expect(service.mentorship_period.finished_on).to eq(ect_finish_date)
        end
      end

      context "when both ECT and mentor are scheduled to leave and mentor leaves first" do
        let(:ect_finish_date) { 3.months.from_now.to_date }
        let(:mentor_finish_date) { 2.months.from_now.to_date }
        let(:mentee) { FactoryBot.create(:ect_at_school_period, started_on: mentee_started_on, finished_on: ect_finish_date) }
        let(:new_mentor) { FactoryBot.create(:mentor_at_school_period, started_on: mentor_started_on, finished_on: mentor_finish_date) }

        it "sets finished_on to the mentor finish date" do
          service.assign!

          expect(service.mentorship_period.finished_on).to eq(mentor_finish_date)
        end
      end
    end

    describe "assigning mentor to ECT who is leaving" do
      let(:ect_finish_date) { 2.months.from_now.to_date }
      let(:mentee) { FactoryBot.create(:ect_at_school_period, started_on: mentee_started_on, finished_on: ect_finish_date) }

      it "successfully creates mentorship period without validation errors" do
        expect { service.assign! }.not_to raise_error
        expect(service.mentorship_period).to be_persisted
        expect(service.mentorship_period.finished_on).to eq(ect_finish_date)
      end

      it "does not raise validation errors" do
        expect { service.assign! }.not_to raise_error
      end
    end

    describe "events" do
      let(:mentorship_period) { MentorshipPeriod.last }

      it "creates the :record_teacher_starts_mentoring_event with the right arguments" do
        allow(Events::Record).to receive(:record_teacher_starts_mentoring_event!).and_call_original

        service.assign!

        expect(Events::Record).to have_received(:record_teacher_starts_mentoring_event!).with(
          hash_including(
            mentee: mentee.teacher,
            mentor: new_mentor.teacher,
            mentorship_period:,
            author:,
            school: new_mentor.school
          )
        )
      end

      it "creates the :record_teacher_starts_being_mentored_event with the right arguments" do
        allow(Events::Record).to receive(:record_teacher_starts_being_mentored_event!).and_call_original

        service.assign!

        expect(Events::Record).to have_received(:record_teacher_starts_being_mentored_event!).with(
          hash_including(
            mentee: mentee.teacher,
            mentor: new_mentor.teacher,
            mentorship_period:,
            author:,
            school: mentee.school
          )
        )
      end
    end
  end

  describe "#mentor_moving_schools?" do
    context "when there are no previous mentor at school periods for this teacher" do
      before do
        FactoryBot.create(:mentor_at_school_period, :ongoing, started_on: mentor_started_on)
      end

      it "returns false" do
        expect(service.send(:mentor_moving_schools?)).to be false
      end
    end

    context "when there are mentor at school periods for other teachers which finish in the future" do
      before do
        FactoryBot.create(:mentor_at_school_period, :ongoing, started_on: mentor_started_on, finished_on: 1.month.from_now)
      end

      it "returns false" do
        expect(service.send(:mentor_moving_schools?)).to be false
      end
    end

    context "when the new mentor teacher has an ongoing mentor at school period at another school" do
      before do
        FactoryBot.create(:mentor_at_school_period, :ongoing, started_on: mentor_started_on, teacher: new_mentor.teacher)
      end

      it "returns true" do
        expect(service.send(:mentor_moving_schools?)).to be true
      end
    end

    context "when the new mentor teacher has an ongoing mentor at school period at several other schools" do
      before do
        FactoryBot.create(:mentor_at_school_period, :ongoing, started_on: mentor_started_on, teacher: new_mentor.teacher)
        FactoryBot.create(:mentor_at_school_period, :ongoing, started_on: mentor_started_on, teacher: new_mentor.teacher)
      end

      it "returns true" do
        expect(service.send(:mentor_moving_schools?)).to be true
      end
    end

    context "when the new mentor teacher has an ongoing mentor at school period at another school which finishes in the future" do
      before do
        FactoryBot.create(:mentor_at_school_period, :ongoing, started_on: mentor_started_on, finished_on: 1.month.from_now, teacher: new_mentor.teacher)
      end

      it "returns true" do
        expect(service.send(:mentor_moving_schools?)).to be true
      end
    end

    context "when the new mentor teacher has an ongoing mentor at school period at another school which finish in the past" do
      before do
        FactoryBot.create(:mentor_at_school_period, started_on: mentor_started_on, finished_on: 1.month.ago, teacher: new_mentor.teacher)
      end

      it "returns true" do
        expect(service.send(:mentor_moving_schools?)).to be true
      end
    end
  end
end
