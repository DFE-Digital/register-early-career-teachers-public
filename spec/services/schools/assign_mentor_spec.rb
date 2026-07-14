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

      context "when the mentee is currently being mentored" do
        let(:current_mentor) do
          FactoryBot.create(
            :mentor_at_school_period,
            :ongoing,
            started_on: current_mentorship_period_started_on,
            school: mentee.school
          )
        end
        let!(:current_mentorship_period) do
          FactoryBot.create(
            :mentorship_period,
            :ongoing,
            started_on: current_mentorship_period_started_on,
            mentee:,
            mentor: current_mentor
          )
        end
        let(:current_mentorship_period_started_on) { current_mentor.started_on }

        context "and the mentorship can start today" do
          let(:mentorship_can_start_today) { true }

          context "and both the mentee and the mentor started at the school " \
                  "in the past" do
            let(:mentee_started_on) { 2.years.ago }
            let(:new_mentor_started_on) { 1.year.ago }
            let(:earliest_possible_start) { Date.current }

            context "and the earliest possible start is after the current mentorship started" do
              let(:current_mentorship_period_started_on) { earliest_possible_start.prev_day }

              it "finishes the current mentorship period" do
                expect { assign! }
                  .to change { current_mentorship_period.reload.finished_on }
                  .from(nil).to(earliest_possible_start.yesterday)
              end
            end

            context "and the earliest possible start is before the current mentorship started" do
              let(:current_mentorship_period_started_on) { earliest_possible_start.next_day }

              it "destroys the current mentorship period" do
                assign!
                expect { current_mentorship_period.reload }
                  .to raise_error(ActiveRecord::RecordNotFound)
              end
            end

            context "and the earliest possible start is when the current mentorship started" do
              let(:current_mentorship_period_started_on) { earliest_possible_start }

              it "destroys the current mentorship period" do
                assign!
                expect { current_mentorship_period.reload }
                  .to raise_error(ActiveRecord::RecordNotFound)
              end
            end
          end

          context "and both the mentee and the mentor are due to start at " \
                  "the school in the future, and the mentee starts later" do
            let(:mentee_started_on) { 3.months.from_now }
            let(:new_mentor_started_on) { 1.month.from_now }
            let(:earliest_possible_start) { mentee.started_on }

            context "and the earliest possible start is after the current mentorship started", skip: "this isn't possible" do
              let(:current_mentorship_period_started_on) { earliest_possible_start.prev_day }

              it "finishes the current mentorship period" do
                expect { assign! }
                  .to change { current_mentorship_period.reload.finished_on }
                  .from(nil).to(earliest_possible_start.yesterday)
              end
            end

            context "and the earliest possible start is before the current mentorship started" do
              let(:current_mentorship_period_started_on) { earliest_possible_start.next_day }

              it "destroys the current mentorship period" do
                assign!
                expect { current_mentorship_period.reload }
                  .to raise_error(ActiveRecord::RecordNotFound)
              end
            end

            context "and the earliest possible start is when the current mentorship started" do
              let(:current_mentorship_period_started_on) { earliest_possible_start }

              it "destroys the current mentorship period" do
                assign!
                expect { current_mentorship_period.reload }
                  .to raise_error(ActiveRecord::RecordNotFound)
              end
            end
          end

          context "and both the mentee and the mentor are due to start at " \
                  "the school in the future, and the mentor starts later" do
            let(:mentee_started_on) { 1.month.from_now }
            let(:new_mentor_started_on) { 3.months.from_now }
            let(:earliest_possible_start) { new_mentor.started_on }

            context "and the earliest possible start is after the current mentorship started" do
              let(:current_mentorship_period_started_on) { earliest_possible_start.prev_day }

              it "finishes the current mentorship period" do
                expect { assign! }
                  .to change { current_mentorship_period.reload.finished_on }
                  .from(nil).to(earliest_possible_start.yesterday)
              end
            end

            context "and the earliest possible start is before the current mentorship started" do
              let(:current_mentorship_period_started_on) { earliest_possible_start.next_day }

              it "destroys the current mentorship period" do
                assign!
                expect { current_mentorship_period.reload }
                  .to raise_error(ActiveRecord::RecordNotFound)
              end
            end

            context "and the earliest possible start is when the current mentorship started" do
              let(:current_mentorship_period_started_on) { earliest_possible_start }

              it "destroys the current mentorship period" do
                assign!
                expect { current_mentorship_period.reload }
                  .to raise_error(ActiveRecord::RecordNotFound)
              end
            end
          end

          context "and the mentee started at the school in the past but the " \
                  "mentor is due to start at the school in the future" do
            let(:mentee_started_on) { 6.months.ago }
            let(:new_mentor_started_on) { 1.month.from_now }
            let(:earliest_possible_start) { new_mentor.started_on }

            context "and the earliest possible start is after the current mentorship started" do
              let(:current_mentorship_period_started_on) { earliest_possible_start.prev_day }

              it "finishes the current mentorship period" do
                expect { assign! }
                  .to change { current_mentorship_period.reload.finished_on }
                  .from(nil).to(earliest_possible_start.yesterday)
              end
            end

            context "and the earliest possible start is before the current mentorship started" do
              let(:current_mentorship_period_started_on) { earliest_possible_start.next_day }

              it "destroys the current mentorship period" do
                assign!
                expect { current_mentorship_period.reload }
                  .to raise_error(ActiveRecord::RecordNotFound)
              end
            end

            context "and the earliest possible start is when the current mentorship started" do
              let(:current_mentorship_period_started_on) { earliest_possible_start }

              it "destroys the current mentorship period" do
                assign!
                expect { current_mentorship_period.reload }
                  .to raise_error(ActiveRecord::RecordNotFound)
              end
            end
          end

          context "and the mentor started at the school in the past but the " \
                  "mentee is due to start at the school in the future" do
            let(:mentee_started_on) { 1.month.from_now }
            let(:new_mentor_started_on) { 6.months.ago }
            let(:earliest_possible_start) { mentee.started_on }

            context "and the earliest possible start is after the current mentorship started", skip: "this isn't possible" do
              let(:current_mentorship_period_started_on) { earliest_possible_start.prev_day }

              it "finishes the current mentorship period" do
                expect { assign! }
                  .to change { current_mentorship_period.reload.finished_on }
                  .from(nil).to(earliest_possible_start.yesterday)
              end
            end

            context "and the earliest possible start is before the current mentorship started" do
              let(:current_mentorship_period_started_on) { earliest_possible_start.next_day }

              it "destroys the current mentorship period" do
                assign!
                expect { current_mentorship_period.reload }
                  .to raise_error(ActiveRecord::RecordNotFound)
              end
            end

            context "and the earliest possible start is when the current mentorship started" do
              let(:current_mentorship_period_started_on) { earliest_possible_start }

              it "destroys the current mentorship period" do
                assign!
                expect { current_mentorship_period.reload }
                  .to raise_error(ActiveRecord::RecordNotFound)
              end
            end
          end
        end

        context "and the mentorship cannot start today" do # (i.e) when the mentor is newly registered and is only mentoring at the new school
          let(:mentorship_can_start_today) { false }

          context "and the mentee started at the school after the mentor" do
            let(:mentee_started_on) { 1.year.ago }
            let(:new_mentor_started_on) { 2.years.ago }
            let(:earliest_possible_start) { mentee.started_on }

            context "and the earliest possible start is after the current mentorship started", skip: "this isn't possible" do
              let(:current_mentorship_period_started_on) { earliest_possible_start.prev_day }

              it "finishes the current mentorship period" do
                expect { assign! }
                  .to change { current_mentorship_period.reload.finished_on }
                  .from(nil).to(earliest_possible_start.yesterday)
              end
            end

            context "and the earliest possible start is before the current mentorship started" do
              let(:current_mentorship_period_started_on) { earliest_possible_start.next_day }

              it "destroys the current mentorship period" do
                assign!
                expect { current_mentorship_period.reload }
                  .to raise_error(ActiveRecord::RecordNotFound)
              end
            end

            context "and the earliest possible start is when the current mentorship started" do
              let(:current_mentorship_period_started_on) { earliest_possible_start }

              it "destroys the current mentorship period" do
                assign!
                expect { current_mentorship_period.reload }
                  .to raise_error(ActiveRecord::RecordNotFound)
              end
            end
          end

          context "and the mentor started at the school after the mentee" do
            let(:mentee_started_on) { 2.years.ago }
            let(:new_mentor_started_on) { 1.year.ago }
            let(:earliest_possible_start) { new_mentor.started_on }

            context "and the earliest possible start is after the current mentorship started" do
              let(:current_mentorship_period_started_on) { earliest_possible_start.prev_day }

              it "finishes the current mentorship period" do
                expect { assign! }
                  .to change { current_mentorship_period.reload.finished_on }
                  .from(nil).to(earliest_possible_start.yesterday)
              end
            end

            context "and the earliest possible start is before the current mentorship started" do
              let(:current_mentorship_period_started_on) { earliest_possible_start.next_day }

              it "destroys the current mentorship period" do
                assign!
                expect { current_mentorship_period.reload }
                  .to raise_error(ActiveRecord::RecordNotFound)
              end
            end

            context "and the earliest possible start is when the current mentorship started" do
              let(:current_mentorship_period_started_on) { earliest_possible_start }

              it "destroys the current mentorship period" do
                assign!
                expect { current_mentorship_period.reload }
                  .to raise_error(ActiveRecord::RecordNotFound)
              end
            end
          end
        end
      end
    end

    describe "assigning the new mentor" do
      context "when the mentorship can start today" do
        let(:mentorship_can_start_today) { true }

        context "and both the mentee and the mentor started at the school " \
                "in the past" do
          let(:mentee_started_on) { 2.years.ago }
          let(:new_mentor_started_on) { 1.year.ago }
          let(:earliest_possible_start) { Date.current }

          context "and neither the mentee and the mentor are due to leave " \
                  "the school" do
            let(:mentee_finished_on) { nil }
            let(:new_mentor_finished_on) { nil }
            let(:latest_possible_finish) { nil }

            it "assigns the new mentor" do
              assign!
              mentorship_period = mentee.reload.mentorship_periods.last

              expect(mentorship_period).to have_attributes(
                mentor: new_mentor,
                started_on: earliest_possible_start,
                finished_on: latest_possible_finish
              )
            end
          end

          context "and only the mentee is due to leave the school" do
            let(:mentee_finished_on) { 2.years.from_now }
            let(:new_mentor_finished_on) { nil }
            let(:latest_possible_finish) { mentee.finished_on }

            it "assigns the new mentor" do
              assign!
              mentorship_period = mentee.reload.mentorship_periods.last

              expect(mentorship_period).to have_attributes(
                mentor: new_mentor,
                started_on: earliest_possible_start,
                finished_on: latest_possible_finish
              )
            end
          end

          context "and only the mentor is due to leave the school" do
            let(:mentee_finished_on) { nil }
            let(:new_mentor_finished_on) { 2.years.from_now }
            let(:latest_possible_finish) { new_mentor.finished_on }

            it "assigns the new mentor" do
              assign!
              mentorship_period = mentee.reload.mentorship_periods.last

              expect(mentorship_period).to have_attributes(
                mentor: new_mentor,
                started_on: earliest_possible_start,
                finished_on: latest_possible_finish
              )
            end
          end

          context "and the mentee is due to leave the school before the mentor" do
            let(:mentee_finished_on) { 1.year.from_now }
            let(:new_mentor_finished_on) { 2.years.from_now }
            let(:latest_possible_finish) { mentee.finished_on }

            it "assigns the new mentor" do
              assign!
              mentorship_period = mentee.reload.mentorship_periods.last

              expect(mentorship_period).to have_attributes(
                mentor: new_mentor,
                started_on: earliest_possible_start,
                finished_on: latest_possible_finish
              )
            end
          end

          context "and the mentor is due to leave the school before the mentee" do
            let(:mentee_finished_on) { 2.years.from_now }
            let(:new_mentor_finished_on) { 1.year.from_now }
            let(:latest_possible_finish) { new_mentor.finished_on }

            it "assigns the new mentor" do
              assign!
              mentorship_period = mentee.reload.mentorship_periods.last

              expect(mentorship_period).to have_attributes(
                mentor: new_mentor,
                started_on: earliest_possible_start,
                finished_on: latest_possible_finish
              )
            end
          end
        end

        context "and both the mentee and the mentor are due to start at " \
                "the school in the future, and the mentee starts later" do
          let(:mentee_started_on) { 3.months.from_now }
          let(:new_mentor_started_on) { 1.month.from_now }
          let(:earliest_possible_start) { mentee.started_on }

          context "and neither the mentee and the mentor are due to leave " \
                  "the school" do
            let(:mentee_finished_on) { nil }
            let(:new_mentor_finished_on) { nil }
            let(:latest_possible_finish) { nil }

            it "assigns the new mentor" do
              assign!
              mentorship_period = mentee.reload.mentorship_periods.last

              expect(mentorship_period).to have_attributes(
                mentor: new_mentor,
                started_on: earliest_possible_start,
                finished_on: latest_possible_finish
              )
            end
          end

          context "and only the mentee is due to leave the school" do
            let(:mentee_finished_on) { 2.years.from_now }
            let(:new_mentor_finished_on) { nil }
            let(:latest_possible_finish) { mentee.finished_on }

            it "assigns the new mentor" do
              assign!
              mentorship_period = mentee.reload.mentorship_periods.last

              expect(mentorship_period).to have_attributes(
                mentor: new_mentor,
                started_on: earliest_possible_start,
                finished_on: latest_possible_finish
              )
            end
          end

          context "and only the mentor is due to leave the school" do
            let(:mentee_finished_on) { nil }
            let(:new_mentor_finished_on) { 2.years.from_now }
            let(:latest_possible_finish) { new_mentor.finished_on }

            it "assigns the new mentor" do
              assign!
              mentorship_period = mentee.reload.mentorship_periods.last

              expect(mentorship_period).to have_attributes(
                mentor: new_mentor,
                started_on: earliest_possible_start,
                finished_on: latest_possible_finish
              )
            end
          end

          context "and the mentee is due to leave the school before the mentor" do
            let(:mentee_finished_on) { 1.year.from_now }
            let(:new_mentor_finished_on) { 2.years.from_now }
            let(:latest_possible_finish) { mentee.finished_on }

            it "assigns the new mentor" do
              assign!
              mentorship_period = mentee.reload.mentorship_periods.last

              expect(mentorship_period).to have_attributes(
                mentor: new_mentor,
                started_on: earliest_possible_start,
                finished_on: latest_possible_finish
              )
            end
          end

          context "and the mentor is due to leave the school before the mentee" do
            let(:mentee_finished_on) { 2.years.from_now }
            let(:new_mentor_finished_on) { 1.year.from_now }
            let(:latest_possible_finish) { new_mentor.finished_on }

            it "assigns the new mentor" do
              assign!
              mentorship_period = mentee.reload.mentorship_periods.last

              expect(mentorship_period).to have_attributes(
                mentor: new_mentor,
                started_on: earliest_possible_start,
                finished_on: latest_possible_finish
              )
            end
          end
        end

        context "and both the mentee and the mentor are due to start at " \
                "the school in the future, and the mentor starts later" do
          let(:mentee_started_on) { 1.month.from_now }
          let(:new_mentor_started_on) { 3.months.from_now }
          let(:earliest_possible_start) { new_mentor.started_on }

          context "and neither the mentee and the mentor are due to leave " \
                  "the school" do
            let(:mentee_finished_on) { nil }
            let(:new_mentor_finished_on) { nil }
            let(:latest_possible_finish) { nil }

            it "assigns the new mentor" do
              assign!
              mentorship_period = mentee.reload.mentorship_periods.last

              expect(mentorship_period).to have_attributes(
                mentor: new_mentor,
                started_on: earliest_possible_start,
                finished_on: latest_possible_finish
              )
            end
          end

          context "and only the mentee is due to leave the school" do
            let(:mentee_finished_on) { 2.years.from_now }
            let(:new_mentor_finished_on) { nil }
            let(:latest_possible_finish) { mentee.finished_on }

            it "assigns the new mentor" do
              assign!
              mentorship_period = mentee.reload.mentorship_periods.last

              expect(mentorship_period).to have_attributes(
                mentor: new_mentor,
                started_on: earliest_possible_start,
                finished_on: latest_possible_finish
              )
            end
          end

          context "and only the mentor is due to leave the school" do
            let(:mentee_finished_on) { nil }
            let(:new_mentor_finished_on) { 2.years.from_now }
            let(:latest_possible_finish) { new_mentor.finished_on }

            it "assigns the new mentor" do
              assign!
              mentorship_period = mentee.reload.mentorship_periods.last

              expect(mentorship_period).to have_attributes(
                mentor: new_mentor,
                started_on: earliest_possible_start,
                finished_on: latest_possible_finish
              )
            end
          end

          context "and the mentee is due to leave the school before the mentor" do
            let(:mentee_finished_on) { 1.year.from_now }
            let(:new_mentor_finished_on) { 2.years.from_now }
            let(:latest_possible_finish) { mentee.finished_on }

            it "assigns the new mentor" do
              assign!
              mentorship_period = mentee.reload.mentorship_periods.last

              expect(mentorship_period).to have_attributes(
                mentor: new_mentor,
                started_on: earliest_possible_start,
                finished_on: latest_possible_finish
              )
            end
          end

          context "and the mentor is due to leave the school before the mentee" do
            let(:mentee_finished_on) { 2.years.from_now }
            let(:new_mentor_finished_on) { 1.year.from_now }
            let(:latest_possible_finish) { new_mentor.finished_on }

            it "assigns the new mentor" do
              assign!
              mentorship_period = mentee.reload.mentorship_periods.last

              expect(mentorship_period).to have_attributes(
                mentor: new_mentor,
                started_on: earliest_possible_start,
                finished_on: latest_possible_finish
              )
            end
          end
        end

        context "and the mentee started at the school in the past but the " \
                "mentor is due to start at the school in the future" do
          let(:mentee_started_on) { 6.months.ago }
          let(:new_mentor_started_on) { 1.month.from_now }
          let(:earliest_possible_start) { new_mentor.started_on }

          context "and neither the mentee and the mentor are due to leave " \
                  "the school" do
            let(:mentee_finished_on) { nil }
            let(:new_mentor_finished_on) { nil }
            let(:latest_possible_finish) { nil }

            it "assigns the new mentor" do
              assign!
              mentorship_period = mentee.reload.mentorship_periods.last

              expect(mentorship_period).to have_attributes(
                mentor: new_mentor,
                started_on: earliest_possible_start,
                finished_on: latest_possible_finish
              )
            end
          end

          context "and only the mentee is due to leave the school" do
            let(:mentee_finished_on) { 2.years.from_now }
            let(:new_mentor_finished_on) { nil }
            let(:latest_possible_finish) { mentee.finished_on }

            it "assigns the new mentor" do
              assign!
              mentorship_period = mentee.reload.mentorship_periods.last

              expect(mentorship_period).to have_attributes(
                mentor: new_mentor,
                started_on: earliest_possible_start,
                finished_on: latest_possible_finish
              )
            end
          end

          context "and only the mentor is due to leave the school" do
            let(:mentee_finished_on) { nil }
            let(:new_mentor_finished_on) { 2.years.from_now }
            let(:latest_possible_finish) { new_mentor.finished_on }

            it "assigns the new mentor" do
              assign!
              mentorship_period = mentee.reload.mentorship_periods.last

              expect(mentorship_period).to have_attributes(
                mentor: new_mentor,
                started_on: earliest_possible_start,
                finished_on: latest_possible_finish
              )
            end
          end

          context "and the mentee is due to leave the school before the mentor" do
            let(:mentee_finished_on) { 1.year.from_now }
            let(:new_mentor_finished_on) { 2.years.from_now }
            let(:latest_possible_finish) { mentee.finished_on }

            it "assigns the new mentor" do
              assign!
              mentorship_period = mentee.reload.mentorship_periods.last

              expect(mentorship_period).to have_attributes(
                mentor: new_mentor,
                started_on: earliest_possible_start,
                finished_on: latest_possible_finish
              )
            end
          end

          context "and the mentor is due to leave the school before the mentee" do
            let(:mentee_finished_on) { 2.years.from_now }
            let(:new_mentor_finished_on) { 1.year.from_now }
            let(:latest_possible_finish) { new_mentor.finished_on }

            it "assigns the new mentor" do
              assign!
              mentorship_period = mentee.reload.mentorship_periods.last

              expect(mentorship_period).to have_attributes(
                mentor: new_mentor,
                started_on: earliest_possible_start,
                finished_on: latest_possible_finish
              )
            end
          end
        end

        context "and the mentor started at the school in the past but the " \
                "mentee is due to start at the school in the future" do
          let(:mentee_started_on) { 1.month.from_now }
          let(:new_mentor_started_on) { 6.months.ago }
          let(:earliest_possible_start) { mentee.started_on }

          context "and neither the mentee and the mentor are due to leave " \
                  "the school" do
            let(:mentee_finished_on) { nil }
            let(:new_mentor_finished_on) { nil }
            let(:latest_possible_finish) { nil }

            it "assigns the new mentor" do
              assign!
              mentorship_period = mentee.reload.mentorship_periods.last

              expect(mentorship_period).to have_attributes(
                mentor: new_mentor,
                started_on: earliest_possible_start,
                finished_on: latest_possible_finish
              )
            end
          end

          context "and only the mentee is due to leave the school" do
            let(:mentee_finished_on) { 2.years.from_now }
            let(:new_mentor_finished_on) { nil }
            let(:latest_possible_finish) { mentee.finished_on }

            it "assigns the new mentor" do
              assign!
              mentorship_period = mentee.reload.mentorship_periods.last

              expect(mentorship_period).to have_attributes(
                mentor: new_mentor,
                started_on: earliest_possible_start,
                finished_on: latest_possible_finish
              )
            end
          end

          context "and only the mentor is due to leave the school" do
            let(:mentee_finished_on) { nil }
            let(:new_mentor_finished_on) { 2.years.from_now }
            let(:latest_possible_finish) { new_mentor.finished_on }

            it "assigns the new mentor" do
              assign!
              mentorship_period = mentee.reload.mentorship_periods.last

              expect(mentorship_period).to have_attributes(
                mentor: new_mentor,
                started_on: earliest_possible_start,
                finished_on: latest_possible_finish
              )
            end
          end

          context "and the mentee is due to leave the school before the mentor" do
            let(:mentee_finished_on) { 1.year.from_now }
            let(:new_mentor_finished_on) { 2.years.from_now }
            let(:latest_possible_finish) { mentee.finished_on }

            it "assigns the new mentor" do
              assign!
              mentorship_period = mentee.reload.mentorship_periods.last

              expect(mentorship_period).to have_attributes(
                mentor: new_mentor,
                started_on: earliest_possible_start,
                finished_on: latest_possible_finish
              )
            end
          end

          context "and the mentor is due to leave the school before the mentee" do
            let(:mentee_finished_on) { 2.years.from_now }
            let(:new_mentor_finished_on) { 1.year.from_now }
            let(:latest_possible_finish) { new_mentor.finished_on }

            it "assigns the new mentor" do
              assign!
              mentorship_period = mentee.reload.mentorship_periods.last

              expect(mentorship_period).to have_attributes(
                mentor: new_mentor,
                started_on: earliest_possible_start,
                finished_on: latest_possible_finish
              )
            end
          end
        end
      end

      context "when the mentorship cannot start today" do # (i.e) when the mentor is newly registered and is only mentoring at the new school
        let(:mentorship_can_start_today) { false }

        context "and the mentee started at the school after the mentor" do
          let(:mentee_started_on) { 1.year.ago }
          let(:new_mentor_started_on) { 2.years.ago }
          let(:earliest_possible_start) { mentee.started_on }

          context "and neither the mentee and the mentor are due to leave " \
                  "the school" do
            let(:mentee_finished_on) { nil }
            let(:new_mentor_finished_on) { nil }
            let(:latest_possible_finish) { nil }

            it "assigns the new mentor" do
              assign!
              mentorship_period = mentee.reload.mentorship_periods.last

              expect(mentorship_period).to have_attributes(
                mentor: new_mentor,
                started_on: earliest_possible_start,
                finished_on: latest_possible_finish
              )
            end
          end

          context "and only the mentee is due to leave the school" do
            let(:mentee_finished_on) { 2.years.from_now }
            let(:new_mentor_finished_on) { nil }
            let(:latest_possible_finish) { mentee.finished_on }

            it "assigns the new mentor" do
              assign!
              mentorship_period = mentee.reload.mentorship_periods.last

              expect(mentorship_period).to have_attributes(
                mentor: new_mentor,
                started_on: earliest_possible_start,
                finished_on: latest_possible_finish
              )
            end
          end

          context "and only the mentor is due to leave the school" do
            let(:mentee_finished_on) { nil }
            let(:new_mentor_finished_on) { 2.years.from_now }
            let(:latest_possible_finish) { new_mentor.finished_on }

            it "assigns the new mentor" do
              assign!
              mentorship_period = mentee.reload.mentorship_periods.last

              expect(mentorship_period).to have_attributes(
                mentor: new_mentor,
                started_on: earliest_possible_start,
                finished_on: latest_possible_finish
              )
            end
          end

          context "and the mentee is due to leave the school before the mentor" do
            let(:mentee_finished_on) { 1.year.from_now }
            let(:new_mentor_finished_on) { 2.years.from_now }
            let(:latest_possible_finish) { mentee.finished_on }

            it "assigns the new mentor" do
              assign!
              mentorship_period = mentee.reload.mentorship_periods.last

              expect(mentorship_period).to have_attributes(
                mentor: new_mentor,
                started_on: earliest_possible_start,
                finished_on: latest_possible_finish
              )
            end
          end

          context "and the mentor is due to leave the school before the mentee" do
            let(:mentee_finished_on) { 2.years.from_now }
            let(:new_mentor_finished_on) { 1.year.from_now }
            let(:latest_possible_finish) { new_mentor.finished_on }

            it "assigns the new mentor" do
              assign!
              mentorship_period = mentee.reload.mentorship_periods.last

              expect(mentorship_period).to have_attributes(
                mentor: new_mentor,
                started_on: earliest_possible_start,
                finished_on: latest_possible_finish
              )
            end
          end
        end

        context "and the mentor started at the school after the mentee" do
          let(:mentee_started_on) { 2.years.ago }
          let(:new_mentor_started_on) { 1.year.ago }
          let(:earliest_possible_start) { new_mentor.started_on }

          context "and neither the mentee and the mentor are due to leave " \
                  "the school" do
            let(:mentee_finished_on) { nil }
            let(:new_mentor_finished_on) { nil }
            let(:latest_possible_finish) { nil }

            it "assigns the new mentor" do
              assign!
              mentorship_period = mentee.reload.mentorship_periods.last

              expect(mentorship_period).to have_attributes(
                mentor: new_mentor,
                started_on: earliest_possible_start,
                finished_on: latest_possible_finish
              )
            end
          end

          context "and only the mentee is due to leave the school" do
            let(:mentee_finished_on) { 2.years.from_now }
            let(:new_mentor_finished_on) { nil }
            let(:latest_possible_finish) { mentee.finished_on }

            it "assigns the new mentor" do
              assign!
              mentorship_period = mentee.reload.mentorship_periods.last

              expect(mentorship_period).to have_attributes(
                mentor: new_mentor,
                started_on: earliest_possible_start,
                finished_on: latest_possible_finish
              )
            end
          end

          context "and only the mentor is due to leave the school" do
            let(:mentee_finished_on) { nil }
            let(:new_mentor_finished_on) { 2.years.from_now }
            let(:latest_possible_finish) { new_mentor.finished_on }

            it "assigns the new mentor" do
              assign!
              mentorship_period = mentee.reload.mentorship_periods.last

              expect(mentorship_period).to have_attributes(
                mentor: new_mentor,
                started_on: earliest_possible_start,
                finished_on: latest_possible_finish
              )
            end
          end

          context "and the mentee is due to leave the school before the mentor" do
            let(:mentee_finished_on) { 1.year.from_now }
            let(:new_mentor_finished_on) { 2.years.from_now }
            let(:latest_possible_finish) { mentee.finished_on }

            it "assigns the new mentor" do
              assign!
              mentorship_period = mentee.reload.mentorship_periods.last

              expect(mentorship_period).to have_attributes(
                mentor: new_mentor,
                started_on: earliest_possible_start,
                finished_on: latest_possible_finish
              )
            end
          end

          context "and the mentor is due to leave the school before the mentee" do
            let(:mentee_finished_on) { 2.years.from_now }
            let(:new_mentor_finished_on) { 1.year.from_now }
            let(:latest_possible_finish) { new_mentor.finished_on }

            it "assigns the new mentor" do
              assign!
              mentorship_period = mentee.reload.mentorship_periods.last

              expect(mentorship_period).to have_attributes(
                mentor: new_mentor,
                started_on: earliest_possible_start,
                finished_on: latest_possible_finish
              )
            end
          end
        end
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
