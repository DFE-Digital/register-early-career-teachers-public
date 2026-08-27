RSpec.describe ECTAtSchoolPeriods::ChangeStartDate do
  subject(:change_start_date) do
    described_class.change(
      ect_at_school_period,
      started_on: new_started_on,
      author:
    )
  end

  include_context "safe_schedules"

  before do
    travel_to(Date.new(2026, 9, 15))
  end

  let(:school) { FactoryBot.create(:school) }
  let(:teacher) { FactoryBot.create(:teacher) }

  let(:author) do
    FactoryBot.create(:school_user, school_urn: school.urn)
  end

  let(:ect_at_school_period) do
    FactoryBot.create(
      :ect_at_school_period,
      :unfinished,
      school:,
      teacher:,
      started_on: current_started_on
    )
  end

  let!(:training_period) do
    FactoryBot.create(
      :training_period,
      :provider_led,
      :unfinished,
      :for_ect,
      ect_at_school_period:,
      started_on: current_started_on
    )
  end

  describe ".change" do
    context "when the new start date is earlier" do
      let(:current_started_on) { Date.new(2026, 10, 1) }
      let(:new_started_on) { Date.new(2026, 9, 1) }

      it "moves the ECT at-school period to the new start date" do
        expect { change_start_date }
          .to change { ect_at_school_period.reload.started_on }
          .from(current_started_on)
          .to(new_started_on)
      end

      it "moves the training period to the later of the new start date and today" do
        expect { change_start_date }
          .to change { training_period.reload.started_on }
          .from(current_started_on)
          .to(Date.new(2026, 9, 15))
      end

      context "when the ECT has a mentorship period" do
        let(:mentor_at_school_period) do
          FactoryBot.create(
            :mentor_at_school_period,
            :unfinished,
            school:,
            started_on: Date.new(2026, 8, 1)
          )
        end

        let!(:mentorship_period) do
          FactoryBot.create(
            :mentorship_period,
            :unfinished,
            mentee: ect_at_school_period,
            mentor: mentor_at_school_period,
            started_on: current_started_on
          )
        end

        it "moves the mentorship period to the later of the ECT and mentor at-school period start dates" do
          expect { change_start_date }
            .to change { mentorship_period.reload.started_on }
            .from(current_started_on)
            .to(new_started_on)
        end
      end

      context "when the mentor at-school period starts after the new ECT at-school period date" do
        let(:mentor_at_school_period) do
          FactoryBot.create(
            :mentor_at_school_period,
            :unfinished,
            school:,
            started_on: Date.new(2026, 9, 10)
          )
        end

        let!(:mentorship_period) do
          FactoryBot.create(
            :mentorship_period,
            :unfinished,
            mentee: ect_at_school_period,
            mentor: mentor_at_school_period,
            started_on: current_started_on
          )
        end

        it "moves the mentorship period to the mentor at-school period start date" do
          expect { change_start_date }
            .to change { mentorship_period.reload.started_on }
            .from(current_started_on)
            .to(Date.new(2026, 9, 10))
        end
      end
    end

    context "when the new start date is later" do
      let(:current_started_on) { Date.new(2026, 9, 1) }
      let(:new_started_on) { Date.new(2026, 10, 1) }

      it "moves the ECT at-school period and training period to the new start date" do
        change_start_date

        expect(ect_at_school_period.reload.started_on)
          .to eq(new_started_on)

        expect(training_period.reload.started_on)
          .to eq(new_started_on)
      end

      context "when the ECT has an unfinished mentorship period" do
        let(:mentor_at_school_period) do
          FactoryBot.create(
            :mentor_at_school_period,
            :unfinished,
            school:,
            started_on: Date.new(2026, 8, 1)
          )
        end

        let!(:mentorship_period) do
          FactoryBot.create(
            :mentorship_period,
            :unfinished,
            mentee: ect_at_school_period,
            mentor: mentor_at_school_period,
            started_on: current_started_on
          )
        end

        it "moves the mentorship period to the new ECT at-school period start date" do
          expect { change_start_date }
            .to change { mentorship_period.reload.started_on }
            .from(current_started_on)
            .to(new_started_on)
        end
      end

      context "when the ECT has a finished mentorship period" do
        let(:mentor_at_school_period) do
          FactoryBot.create(
            :mentor_at_school_period,
            :unfinished,
            school:,
            started_on: Date.new(2026, 8, 1)
          )
        end

        let!(:mentorship_period) do
          FactoryBot.create(
            :mentorship_period,
            mentee: ect_at_school_period,
            mentor: mentor_at_school_period,
            started_on: current_started_on,
            finished_on: mentorship_finished_on
          )
        end

        context "when the new start date is before the mentorship end date" do
          let(:mentorship_finished_on) { Date.new(2026, 10, 2) }

          it "moves the mentorship period start date" do
            expect { change_start_date }
              .to change { mentorship_period.reload.started_on }
              .from(current_started_on)
              .to(new_started_on)

            expect(mentorship_period).to be_persisted
          end
        end

        context "when the new start date equals the mentorship end date" do
          let(:mentorship_finished_on) { new_started_on }

          it "removes the mentorship period" do
            expect { change_start_date }
              .to change(MentorshipPeriod, :count)
              .by(-1)

            expect(MentorshipPeriod.exists?(mentorship_period.id))
              .to be(false)
          end
        end

        context "when the new start date is after the mentorship end date" do
          let(:mentorship_finished_on) { Date.new(2026, 9, 30) }

          it "removes the mentorship period" do
            expect { change_start_date }
              .to change(MentorshipPeriod, :count)
              .by(-1)

            expect(MentorshipPeriod.exists?(mentorship_period.id))
              .to be(false)
          end
        end
      end
    end

    context "when the ECT does not have a mentorship period" do
      let(:current_started_on) { Date.new(2026, 9, 1) }
      let(:new_started_on) { Date.new(2026, 10, 1) }

      it "updates the ECT at-school period and training period" do
        expect { change_start_date }.not_to raise_error

        expect(ect_at_school_period.reload.started_on)
          .to eq(new_started_on)

        expect(training_period.reload.started_on)
          .to eq(new_started_on)

        expect(ect_at_school_period.mentorship_periods)
          .to be_empty
      end
    end

    context "when the training period has a schedule" do
      let(:current_started_on) { Date.new(2026, 9, 1) }
      let(:new_started_on) { Date.new(2026, 10, 1) }

      it "does not change the training period schedule" do
        original_schedule = training_period.schedule

        change_start_date

        expect(training_period.reload.schedule)
          .to eq(original_schedule)
      end
    end

    context "when the ECT previously attended another school" do
      let(:current_started_on) { Date.new(2026, 10, 1) }
      let(:new_started_on) { Date.new(2026, 9, 1) }
      let(:previous_school) { FactoryBot.create(:school) }

      let!(:previous_ect_at_school_period) do
        FactoryBot.create(
          :ect_at_school_period,
          teacher:,
          school: previous_school,
          started_on: Date.new(2025, 9, 1),
          finished_on: Date.new(2026, 8, 31)
        )
      end

      let!(:previous_training_period) do
        FactoryBot.create(
          :training_period,
          :school_led,
          :for_ect,
          ect_at_school_period: previous_ect_at_school_period,
          started_on: Date.new(2025, 9, 1),
          finished_on: Date.new(2026, 8, 31)
        )
      end

      let(:previous_mentor_at_school_period) do
        FactoryBot.create(
          :mentor_at_school_period,
          school: previous_school,
          started_on: Date.new(2025, 9, 1),
          finished_on: Date.new(2026, 8, 31)
        )
      end

      let!(:previous_mentorship_period) do
        FactoryBot.create(
          :mentorship_period,
          mentee: previous_ect_at_school_period,
          mentor: previous_mentor_at_school_period,
          started_on: Date.new(2025, 9, 1),
          finished_on: Date.new(2026, 8, 31)
        )
      end

      it "does not change periods associated with the previous school" do
        previous_dates = {
          ect_at_school_period:
            previous_ect_at_school_period.started_on,
          training_period:
            previous_training_period.started_on,
          mentorship_period:
            previous_mentorship_period.started_on
        }

        change_start_date

        expect(previous_ect_at_school_period.reload.started_on)
          .to eq(previous_dates[:ect_at_school_period])

        expect(previous_training_period.reload.started_on)
          .to eq(previous_dates[:training_period])

        expect(previous_mentorship_period.reload.started_on)
          .to eq(previous_dates[:mentorship_period])
      end
    end

    context "when the change succeeds" do
      let(:current_started_on) { Date.new(2026, 9, 1) }
      let(:new_started_on) { Date.new(2026, 10, 1) }

      it "records a school start-date change event" do
        expect(Events::Record)
          .to receive(
            :record_teacher_school_start_date_updated_event!
          )
          .with(
            old_start_date: current_started_on,
            new_start_date: new_started_on,
            author:,
            ect_at_school_period:,
            school:,
            teacher:,
            happened_at: Time.current
          )

        change_start_date
      end
    end

    context "when one of the period updates is invalid" do
      let(:current_started_on) { Date.new(2026, 9, 1) }
      let(:new_started_on) { Date.new(2026, 10, 1) }

      let(:mentor_at_school_period) do
        FactoryBot.create(
          :mentor_at_school_period,
          school:,
          started_on: Date.new(2026, 8, 1),
          finished_on: Date.new(2026, 9, 30)
        )
      end

      let!(:mentorship_period) do
        FactoryBot.create(
          :mentorship_period,
          mentee: ect_at_school_period,
          mentor: mentor_at_school_period,
          started_on: current_started_on,
          finished_on: Date.new(2026, 9, 30)
        )
      end

      before do
        allow(ect_at_school_period)
          .to receive(:update!)
          .with(started_on: new_started_on)
          .and_raise(
            ActiveRecord::RecordInvalid.new(ect_at_school_period)
          )
      end

      it "rolls back all changes" do
        expect { change_start_date }
          .to raise_error(ActiveRecord::RecordInvalid)

        expect(ect_at_school_period.reload.started_on)
          .to eq(current_started_on)

        expect(training_period.reload.started_on)
          .to eq(current_started_on)

        restored_mentorship_period =
          MentorshipPeriod.find(mentorship_period.id)

        expect(restored_mentorship_period.started_on)
          .to eq(current_started_on)

        expect(restored_mentorship_period.finished_on)
          .to eq(Date.new(2026, 9, 30))
      end

      it "does not record an event" do
        expect(Events::Record)
          .not_to receive(
            :record_teacher_school_start_date_updated_event!
          )

        expect { change_start_date }
          .to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end
