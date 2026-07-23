RSpec.describe Schools::AssignMentor do
  subject(:service) do
    described_class.new(
      ect_at_school_period: mentee,
      mentor_at_school_period: new_mentor,
      mentorship_can_start_today:,
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
  let(:mentorship_can_start_today) { true }

  describe "#assign!" do
    subject(:assign!) { service.assign! }

    describe "closing current mentorship" do
      context "when the mentee is not currently being mentored" do
        let!(:current_mentorship_period) { nil }

        it "does not raise an error" do
          expect { assign! }.not_to raise_error
        end
      end

      context "when a previous mentorship has finished" do
        let(:mentorship_can_start_today) { false }
        let(:new_mentor_started_on) { 1.month.ago }

        let(:previous_mentor) do
          FactoryBot.create(
            :mentor_at_school_period,
            :ongoing,
            school: mentee.school,
            started_on: 1.year.ago
          )
        end

        let!(:previous_mentorship_period) do
          FactoryBot.create(
            :mentorship_period,
            mentee:,
            mentor: previous_mentor,
            started_on: 1.year.ago,
            finished_on: 2.weeks.ago
          )
        end

        it "assigns the new mentor without overlapping the previous mentorship" do
          expect { assign! }.not_to raise_error

          new_mentorship = mentee.reload.mentorship_periods.find_by!(
            mentor: new_mentor
          )

          expect(new_mentorship.started_on)
            .to eq(previous_mentorship_period.finished_on.next_day)
        end
      end


      context "when the mentee is currently being mentored" do
        let(:current_mentor) do
          FactoryBot.create(
            :mentor_at_school_period,
            :ongoing,
            started_on: 6.months.ago,
            school: mentee.school
          )
        end
        let!(:current_mentorship_period) do
          FactoryBot.create(
            :mentorship_period,
            :ongoing,
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

      context "when the current mentorship already has a future end date" do
        let(:current_mentor) do
          FactoryBot.create(
            :mentor_at_school_period,
            :ongoing,
            started_on: 6.months.ago,
            school: mentee.school
          )
        end

        let!(:current_mentorship_period) do
          FactoryBot.create(
            :mentorship_period,
            started_on: current_mentor.started_on,
            finished_on: 1.week.from_now,
            mentee:,
            mentor: current_mentor
          )
        end

        it "finishes the current mentorship before assigning the new mentor" do
          expect { assign! }.not_to raise_error

          expect(current_mentorship_period.reload.finished_on)
            .to eq(Date.yesterday)
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
