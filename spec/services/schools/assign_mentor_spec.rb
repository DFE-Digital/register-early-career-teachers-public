RSpec.describe Schools::AssignMentor do
  subject(:service) do
    described_class.new(
      ect_at_school_period: mentee,
      mentor_at_school_period: new_mentor,
      mentor_is_transferring_schools:,
      author:
    )
  end

  let(:author) { FactoryBot.create(:school_user, school_urn: mentee.school.urn) }

  let(:mentee) do
    FactoryBot.create(
      :ect_at_school_period,
      started_on: mentee_started_on,
      finished_on: mentee_finished_on
    )
  end
  let(:new_mentor) do
    FactoryBot.create(
      :mentor_at_school_period,
      started_on: new_mentor_started_on,
      finished_on: new_mentor_finished_on,
      school: mentee.school
    )
  end

  let(:mentee_started_on) { 2.years.ago }
  let(:mentee_finished_on) { nil }
  let(:new_mentor_started_on) { 1.year.ago }
  let(:new_mentor_finished_on) { nil }
  let(:mentor_is_transferring_schools) { false }

  describe "#assign!" do
    subject(:assign!) { service.assign! }

    describe "closing current mentorship" do
      context "when the mentee is not currently being mentored" do
        let!(:current_mentorship_period) { nil }

        it "does not raise an error" do
          expect { assign! }.not_to raise_error
        end
      end

      context "when the mentee is currently being mentored" do
        let(:current_mentor) do
          FactoryBot.create(
            :mentor_at_school_period,
            :unfinished,
            started_on: 6.months.ago,
            school: mentee.school
          )
        end
        let!(:current_mentorship_period) do
          FactoryBot.create(
            :mentorship_period,
            :unfinished,
            started_on: current_mentor.started_on,
            mentee:,
            mentor: current_mentor
          )
        end

        before do
          allow(Schools::MentorAssignment::MentorshipPeriods::DatesResolver)
            .to receive(:new)
            .and_return(double(earliest_possible_start:, latest_possible_finish: nil))
        end

        context "and the earliest possible start is after the current mentorship started" do
          let(:earliest_possible_start) { current_mentorship_period.started_on.next_day }

          it "finishes the current mentorship period" do
            expect { assign! }
              .to change { current_mentorship_period.reload.finished_on }
              .from(nil).to(earliest_possible_start.yesterday)
          end
        end

        context "and the earliest possible start is before the current mentorship started" do
          let(:earliest_possible_start) { current_mentorship_period.started_on.prev_day }

          it "destroys the current mentorship period" do
            assign!
            expect { current_mentorship_period.reload }
              .to raise_error(ActiveRecord::RecordNotFound)
          end

          it "retains events associated with the current mentorship period" do
            event_one = FactoryBot.create(:event, mentorship_period: current_mentorship_period)
            event_two = FactoryBot.create(:event, mentorship_period: current_mentorship_period)

            assign!

            expect(event_one.reload.mentorship_period_id).to be_nil
            expect(event_two.reload.mentorship_period_id).to be_nil
            expect(Event.exists?(event_one.id)).to be true
            expect(Event.exists?(event_two.id)).to be true
          end
        end

        context "and the earliest possible start is when the current mentorship started" do
          let(:earliest_possible_start) { current_mentorship_period.started_on }

          it "destroys the current mentorship period" do
            assign!
            expect { current_mentorship_period.reload }
              .to raise_error(ActiveRecord::RecordNotFound)
          end
        end
      end
    end

    describe "closing upcoming mentorships" do
      let(:current_mentor) do
        FactoryBot.create(
          :mentor_at_school_period,
          :unfinished,
          started_on: 6.months.ago,
          school: mentee.school
        )
      end
      let(:upcoming_mentor) do
        FactoryBot.create(
          :mentor_at_school_period,
          :unfinished,
          started_on: 6.months.ago,
          school: mentee.school
        )
      end
      let!(:current_mentorship_period) do
        FactoryBot.create(
          :mentorship_period,
          mentee:,
          mentor: current_mentor,
          started_on: 6.months.ago,
          finished_on: 1.month.from_now
        )
      end
      let!(:upcoming_mentorship_period) do
        FactoryBot.create(
          :mentorship_period,
          :unfinished,
          mentee:,
          mentor: upcoming_mentor,
          started_on: 1.month.from_now.next_day
        )
      end

      it "destroys the upcoming mentorship period" do
        assign!

        expect { upcoming_mentorship_period.reload }
          .to raise_error(ActiveRecord::RecordNotFound)
      end

      it "destroys the events recorded against the upcoming mentorship period" do
        FactoryBot.create(:event, mentorship_period: upcoming_mentorship_period)

        expect { assign! }
          .to change { Event.where(mentorship_period: upcoming_mentorship_period).count }
          .from(1).to(0)
      end

      it "finishes the current mentorship period the day before the new one starts" do
        expect { assign! }
          .to change { current_mentorship_period.reload.finished_on }
          .to(Date.yesterday)
      end

      it "leaves the new mentor as the only current or upcoming mentor" do
        assign!

        expect(mentee.reload.mentorship_periods.current_or_future.map(&:mentor))
          .to contain_exactly(new_mentor)
      end

      context "when the new mentor starts in the future" do
        let(:new_mentor_started_on) { 2.months.from_now }

        it "destroys the upcoming mentorship period" do
          assign!

          expect { upcoming_mentorship_period.reload }
            .to raise_error(ActiveRecord::RecordNotFound)
        end

        it "does not extend the current mentorship period" do
          expect { assign! }
            .not_to(change { current_mentorship_period.reload.finished_on })
        end

        it "starts the new mentorship when the new mentor starts" do
          assign!

          expect(mentee.reload.mentorship_periods.last)
            .to have_attributes(mentor: new_mentor, started_on: new_mentor_started_on.to_date)
        end
      end
    end

    describe "assigning the new mentor" do
      before do
        allow(Schools::MentorAssignment::MentorshipPeriods::DatesResolver)
          .to receive(:new)
          .and_return(
            double(
              earliest_possible_start: Date.current,
              latest_possible_finish: 1.year.from_now.to_date
            )
          )
      end

      it "assigns the new mentor" do
        assign!
        mentorship_period = mentee.reload.mentorship_periods.last

        expect(mentorship_period).to have_attributes(
          mentor: new_mentor,
          started_on: Date.current,
          finished_on: 1.year.from_now.to_date
        )
      end

      it "passes whether the mentor is transferring schools to the dates resolver" do
        assign!

        expect(Schools::MentorAssignment::MentorshipPeriods::DatesResolver)
          .to have_received(:new)
          .with(
            ect_at_school_period: mentee,
            mentor_at_school_period: new_mentor,
            mentor_is_transferring_schools:
          )
          .at_least(:once)
      end
    end

    describe "recording events" do
      it "records a `teacher_starts_being_mentored` event" do
        allow(Events::Record)
          .to receive(:record_teacher_starts_being_mentored_event!)

        assign!

        expect(Events::Record)
          .to have_received(:record_teacher_starts_being_mentored_event!)
          .with(
            school: mentee.school,
            mentee: mentee.teacher,
            mentor: new_mentor.teacher,
            ect_at_school_period: mentee,
            mentorship_period: MentorshipPeriod.last,
            author:
          )
      end

      it "records a `teacher_starts_mentoring` event" do
        allow(Events::Record)
          .to receive(:record_teacher_starts_mentoring_event!)

        assign!

        expect(Events::Record)
          .to have_received(:record_teacher_starts_mentoring_event!)
          .with(
            school: new_mentor.school,
            mentee: mentee.teacher,
            mentor: new_mentor.teacher,
            mentor_at_school_period: new_mentor,
            mentorship_period: MentorshipPeriod.last,
            author:
          )
      end
    end
  end
end
