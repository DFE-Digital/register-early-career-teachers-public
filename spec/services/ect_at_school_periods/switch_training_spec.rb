module ECTAtSchoolPeriods
  RSpec.describe SwitchTraining do
    let(:ect_at_school_period) do
      FactoryBot.create(:ect_at_school_period, :ongoing, started_on: 2.weeks.ago)
    end

    let(:mentor_at_school_period) do
      FactoryBot.create(
        :mentor_at_school_period,
        :ongoing,
        started_on: ect_at_school_period.started_on,
        school: ect_at_school_period.school
      )
    end

    let!(:mentorship_period) do
      FactoryBot.create(
        :mentorship_period,
        mentee: ect_at_school_period,
        mentor: mentor_at_school_period
      )
    end

    let(:author) do
      FactoryBot.create(:school_user, school_urn: ect_at_school_period.school.urn)
    end

    describe ".to_school_led" do
      context "when the `current_or_next_training_period` is provider-led" do
        context "when there is a confirmed school partnership" do
          let!(:training_period) do
            FactoryBot.create(
              :training_period,
              :for_ect,
              :ongoing,
              :provider_led,
              :with_school_partnership,
              ect_at_school_period:,
              started_on: ect_at_school_period.started_on
            )
          end

          it "finishes the existing training period" do
            freeze_time

            SwitchTraining.to_school_led(ect_at_school_period, author:)

            expect { training_period.reload }.not_to raise_error
            expect(training_period.finished_on).to eq(Date.current)
          end

          it "creates a new school-led training period" do
            SwitchTraining.to_school_led(ect_at_school_period, author:)

            expect(ect_at_school_period.reload).to be_school_led_training_programme
          end
        end

        context "when there is no confirmed school partnership" do
          let!(:training_period) do
            FactoryBot.create(
              :training_period,
              :for_ect,
              :ongoing,
              :provider_led,
              :with_only_expression_of_interest,
              ect_at_school_period:,
              started_on: ect_at_school_period.started_on
            )
          end

          it "removes the existing training period" do
            SwitchTraining.to_school_led(ect_at_school_period, author:)

            expect { training_period.reload }
              .to raise_error(ActiveRecord::RecordNotFound)
          end

          it "creates a new school-led training period" do
            SwitchTraining.to_school_led(ect_at_school_period, author:)

            expect(ect_at_school_period.reload).to be_school_led_training_programme
          end
        end

        context "when the switch happens on the same day the training period started" do
          let!(:training_period) do
            FactoryBot.create(
              :training_period,
              :for_ect,
              :ongoing,
              :provider_led,
              :with_school_partnership,
              ect_at_school_period:,
              started_on: Date.current
            )
          end

          it "removes the existing training period" do
            freeze_time

            SwitchTraining.to_school_led(ect_at_school_period, author:)

            expect { training_period.reload }.to raise_error(ActiveRecord::RecordNotFound)
          end

          it "creates a new school-led training period" do
            SwitchTraining.to_school_led(ect_at_school_period, author:)

            expect(ect_at_school_period.reload).to be_school_led_training_programme
          end
        end

        context "when the switch happens before the ECT has started" do
          let(:ect_at_school_period) do
            FactoryBot.create(:ect_at_school_period, :not_started_yet)
          end

          let!(:training_period) do
            FactoryBot.create(
              :training_period,
              :for_ect,
              :not_started_yet,
              :provider_led,
              :with_school_partnership,
              ect_at_school_period:,
              started_on: ect_at_school_period.started_on
            )
          end

          it "removes the existing training period" do
            SwitchTraining.to_school_led(ect_at_school_period, author:)

            expect { training_period.reload }
              .to raise_error(ActiveRecord::RecordNotFound)
          end

          it "creates a new school-led training period that starts on the ECT start date" do
            SwitchTraining.to_school_led(ect_at_school_period, author:)

            expect(ect_at_school_period.reload).to be_school_led_training_programme
            new_training_period = TrainingPeriod.last
            expect(new_training_period.started_on).to eq(ect_at_school_period.started_on)
          end
        end
      end

      context "when the `current_or_next_training_period` is already school-led" do
        let!(:training_period) do
          FactoryBot.create(
            :training_period,
            :for_ect,
            :ongoing,
            :school_led,
            ect_at_school_period:,
            started_on: ect_at_school_period.started_on
          )
        end

        it "raises an error" do
          expect { SwitchTraining.to_school_led(ect_at_school_period, author:) }
            .to raise_error(IncorrectTrainingProgrammeError)
        end
      end

      context "when there is no `current_or_next_training_period`" do
        before do
          allow(ect_at_school_period).to receive(:current_or_next_training_period).and_return(nil)
        end

        it "creates a new school-led training period" do
          expect {
            SwitchTraining.to_school_led(ect_at_school_period, author:)
          }.to change(TrainingPeriod, :count).by(1)

          ect_at_school_period_from_database = ECTAtSchoolPeriod.find(ect_at_school_period.id)

          expect(ect_at_school_period_from_database).to be_school_led_training_programme
        end
      end

      context "when the `ECTAtSchoolPeriod` has a `finished_on` date" do
        let(:ect_at_school_period) do
          FactoryBot.create(
            :ect_at_school_period,
            started_on: 2.weeks.ago,
            finished_on: 6.months.from_now
          )
        end

        it "creates a training period that finishes on the same date" do
          SwitchTraining.to_school_led(ect_at_school_period, author:)

          new_training_period = ect_at_school_period.reload.latest_training_period
          expect(new_training_period).not_to be_ongoing
          expect(new_training_period.finished_on).to eq(ect_at_school_period.finished_on)
        end
      end

      context "when the `ECTAtSchoolPeriod` does not have a `finished_on` date" do
        let(:ect_at_school_period) do
          FactoryBot.create(:ect_at_school_period, :ongoing)
        end

        it "creates an ongoing training period" do
          SwitchTraining.to_school_led(ect_at_school_period, author:)

          new_training_period = ect_at_school_period.reload.latest_training_period
          expect(new_training_period).to be_ongoing
        end
      end

      context "when the record is not a `ECTAtSchoolPeriod`" do
        let(:ect_at_school_period) do
          FactoryBot.create(:mentor_at_school_period, :ongoing)
        end
        let(:mentorship_period) { nil }

        it "raises an error" do
          expect { SwitchTraining.to_school_led(ect_at_school_period, author:) }
            .to raise_error(ArgumentError)
        end
      end
    end

    describe ".to_provider_led" do
      let!(:contract_period) do
        FactoryBot.create(:contract_period, :with_schedules, :current)
      end
      let(:lead_provider) { FactoryBot.create(:lead_provider) }
      let!(:active_lead_provider) do
        FactoryBot.create(
          :active_lead_provider,
          lead_provider:,
          contract_period:
        )
      end

      context "when the `current_or_next_training_period` is school-led" do
        let!(:training_period) do
          FactoryBot.create(
            :training_period,
            :for_ect,
            :ongoing,
            :school_led,
            ect_at_school_period:,
            started_on: ect_at_school_period.started_on
          )
        end

        context "when there is a confirmed school partnership" do
          let!(:lead_provider_delivery_partnership) do
            FactoryBot.create(
              :lead_provider_delivery_partnership,
              active_lead_provider:
            )
          end
          let!(:school_partnership) do
            FactoryBot.create(
              :school_partnership,
              lead_provider_delivery_partnership:,
              school: ect_at_school_period.school
            )
          end

          it "finishes the existing training period" do
            freeze_time

            SwitchTraining.to_provider_led(ect_at_school_period, lead_provider:, author:)

            expect { training_period.reload }.not_to raise_error
            expect(training_period.finished_on).to eq(Date.current)
          end

          it "creates a new provider-led training period with that partnership" do
            SwitchTraining.to_provider_led(ect_at_school_period, lead_provider:, author:)

            expect(ect_at_school_period.reload).to be_provider_led_training_programme
            new_training_period = ect_at_school_period.training_periods.last
            expect(new_training_period.school_partnership).to eq(school_partnership)
            expect(new_training_period.expression_of_interest).to be_nil
          end

          context "when the switch happens on the last day of the current contract period" do
            around do |example|
              travel_to(Date.new(2025, 5, 31)) do
                example.run
              end
            end

            it "finds the existing partnership and assigns it" do
              SwitchTraining.to_provider_led(ect_at_school_period, lead_provider:, author:)

              new_training_period = ect_at_school_period.training_periods.last
              expect(new_training_period.school_partnership).to eq(school_partnership)
            end
          end
        end

        context "when there is no confirmed school partnership" do
          it "finishes the existing training period" do
            freeze_time

            SwitchTraining.to_provider_led(ect_at_school_period, lead_provider:, author:)

            expect { training_period.reload }.not_to raise_error
            expect(training_period.finished_on).to eq(Date.current)
          end

          it "creates a new provider-led training period with an expression of interest" do
            SwitchTraining.to_provider_led(ect_at_school_period, lead_provider:, author:)

            expect(ect_at_school_period.reload).to be_provider_led_training_programme
            new_training_period = ect_at_school_period.training_periods.last
            expect(new_training_period.school_partnership).to be_nil
            expect(new_training_period.expression_of_interest).to eq(active_lead_provider)
          end

          context "when the switch happens on the last day of the current contract period" do
            around do |example|
              travel_to(Date.new(2025, 5, 31)) do
                example.run
              end
            end

            it "finds the active_lead_provider with the correct contract period" do
              SwitchTraining.to_provider_led(ect_at_school_period, lead_provider:, author:)

              new_training_period = ect_at_school_period.training_periods.last
              expect(new_training_period.expression_of_interest).to eq(active_lead_provider)
            end
          end
        end

        context "when the switch happens on the same day the training period started" do
          let!(:training_period) do
            FactoryBot.create(
              :training_period,
              :for_ect,
              :ongoing,
              :school_led,
              ect_at_school_period:,
              started_on: Date.current
            )
          end

          it "finishes the existing training period" do
            freeze_time

            SwitchTraining.to_provider_led(ect_at_school_period, lead_provider:, author:)

            expect { training_period.reload }.to raise_error(ActiveRecord::RecordNotFound)
          end

          it "creates a new provider-led training period with an expression of interest" do
            SwitchTraining.to_provider_led(ect_at_school_period, lead_provider:, author:)

            expect(ect_at_school_period.reload).to be_provider_led_training_programme
            new_training_period = ect_at_school_period.training_periods.last
            expect(new_training_period.school_partnership).to be_nil
            expect(new_training_period.expression_of_interest).to eq(active_lead_provider)
          end
        end

        context "when the switch happens before the ECT has started" do
          let(:ect_at_school_period) do
            FactoryBot.create(:ect_at_school_period, :not_started_yet)
          end

          let!(:training_period) do
            FactoryBot.create(
              :training_period,
              :for_ect,
              :not_started_yet,
              :school_led,
              ect_at_school_period:,
              started_on: ect_at_school_period.started_on
            )
          end

          it "removes the existing training period" do
            SwitchTraining.to_provider_led(ect_at_school_period, lead_provider:, author:)

            expect { training_period.reload }
              .to raise_error(ActiveRecord::RecordNotFound)
          end

          it "creates a new provider-led training period that starts on the ECT start date" do
            SwitchTraining.to_provider_led(ect_at_school_period, lead_provider:, author:)

            expect(ect_at_school_period.reload).to be_provider_led_training_programme
            new_training_period = TrainingPeriod.last
            expect(new_training_period.started_on).to eq(ect_at_school_period.started_on)
          end

          context "when the ect starts in the next contract period" do
            around do |example|
              travel_to(Date.new(2026, 5, 31)) do
                example.run
              end
            end

            let(:ect_at_school_period) do
              FactoryBot.create(:ect_at_school_period, :ongoing, started_on: 2.weeks.from_now)
            end

            let(:future_contract_period) { FactoryBot.create(:contract_period, :with_schedules, year: 2026) }

            let!(:future_active_lead_provider) do
              FactoryBot.create(
                :active_lead_provider,
                lead_provider:,
                contract_period: future_contract_period
              )
            end

            it "creates a new provider-led training period that starts on the ECT start date" do
              SwitchTraining.to_provider_led(ect_at_school_period, lead_provider:, author:)

              expect(ect_at_school_period.reload).to be_provider_led_training_programme
              new_training_period = TrainingPeriod.last
              expect(new_training_period.started_on).to eq(ect_at_school_period.started_on)
              expect(new_training_period.expression_of_interest).to eq(future_active_lead_provider)
            end
          end
        end
      end

      context "when the `current_or_next_training_period` is already provider-led" do
        let!(:training_period) do
          FactoryBot.create(
            :training_period,
            :for_ect,
            :ongoing,
            :provider_led,
            ect_at_school_period:,
            started_on: ect_at_school_period.started_on
          )
        end

        it "raises an error" do
          expect { SwitchTraining.to_provider_led(ect_at_school_period, lead_provider:, author:) }
            .to raise_error(IncorrectTrainingProgrammeError)
        end
      end

      context "when there are previous provider-led training periods in an earlier contract periods" do
        let(:contract_period_2024) { FactoryBot.create(:contract_period, :with_schedules, year: 2024) }
        let(:contract_period_2021) { FactoryBot.create(:contract_period, :with_schedules, :with_payments_frozen, year: 2021) }
        let!(:extended_schedule) { FactoryBot.create(:schedule, contract_period: contract_period_2024, identifier: "ecf-extended-september") }

        let(:ect_at_school_period) do
          FactoryBot.create(:ect_at_school_period, :ongoing, started_on:)
        end

        context "when there is a confirmed school partnership" do
          let(:school_partnership) do
            FactoryBot.create(
              :school_partnership,
              :for_year,
              year: contract_period.year,
              school: ect_at_school_period.school
            )
          end

          let!(:previous_training_period) do
            FactoryBot.create(
              :training_period,
              :for_ect,
              :provider_led,
              ect_at_school_period:,
              school_partnership:,
              started_on:,
              finished_on: previous_training_period_finished_on
            )
          end

          let!(:training_period) do
            FactoryBot.create(
              :training_period,
              :for_ect,
              :ongoing,
              :school_led,
              ect_at_school_period:,
              started_on: previous_training_period_finished_on + 1.day
            )
          end

          context "when there is one previous provider-led training period" do
            context "when the earlier contract period is open" do
              let(:started_on) { Date.new(2024, 6, 1) }
              let(:previous_training_period_finished_on) { 2.months.ago }
              let(:contract_period) { contract_period_2024 }

              it "finishes the existing training period" do
                SwitchTraining.to_provider_led(ect_at_school_period, lead_provider:, author:)

                expect { training_period.reload }.not_to raise_error
                expect(training_period.finished_on).to eq(Date.current)
              end

              it "retains the previous schedule and contract period" do
                SwitchTraining.to_provider_led(ect_at_school_period, lead_provider:, author:)

                new_training_period = ect_at_school_period.reload.training_periods.last
                schedule = new_training_period.schedule
                expect(schedule).to eq(previous_training_period.schedule)
                expect(schedule.contract_period).to eq(contract_period_2024)
              end

              it "does not set the ECT's payments frozen year" do
                expect {
                  SwitchTraining.to_provider_led(ect_at_school_period, lead_provider:, author:)
                }.not_to change(ect_at_school_period.teacher, :ect_payments_frozen_year)
              end
            end

            context "when the earlier contract period is closed" do
              let(:started_on) { Date.new(2021, 9, 1) }
              let(:previous_training_period_finished_on) { Date.new(2021, 10, 31) }
              let(:contract_period) { contract_period_2021 }

              before do
                FactoryBot.create(:active_lead_provider, :for_year, year: 2024, lead_provider:)
              end

              it "finishes the existing training period" do
                SwitchTraining.to_provider_led(ect_at_school_period, lead_provider:, author:)

                expect { training_period.reload }.not_to raise_error
                expect(training_period.finished_on).to eq(Date.current)
              end

              it "moves to the successor contract period with an extended schedule" do
                SwitchTraining.to_provider_led(ect_at_school_period, lead_provider:, author:)

                expect(ect_at_school_period.reload).to be_provider_led_training_programme
                new_training_period = ect_at_school_period.reload.training_periods.last
                schedule = new_training_period.schedule
                expect(schedule.contract_period).to eq(contract_period_2024)
                expect(schedule.identifier).to eq("ecf-extended-september")
              end

              it "sets the ECT's payments frozen year to 2021" do
                expect {
                  SwitchTraining.to_provider_led(ect_at_school_period, lead_provider:, author:)
                }.to change(ect_at_school_period.teacher, :ect_payments_frozen_year).from(nil).to(2021)
              end
            end
          end

          context "when there are two previous provider-led training periods" do
            # This scenario is to assert that it only looks at the last provider-led period
            # If both periods are in closed contract periods we cannot test the ordering because the outcome is the same
            # Thus we test only when there are two periods - one in an open contract period - one in a closed period
            # And the period in a closed contract period must be before the period in the open contract period

            let(:started_on) { Date.new(2021, 9, 1) }
            let(:previous_training_period_finished_on) { Date.new(2024, 9, 1) }
            let(:second_training_period_finished_on) { 1.month.ago }
            let(:contract_period) { contract_period_2021 }
            let(:school_partnership_2024) { FactoryBot.create(:school_partnership, :for_year, year: 2024, lead_provider:, school: ect_at_school_period.school) }

            let!(:second_training_period) do
              FactoryBot.create(
                :training_period,
                :for_ect,
                :provider_led,
                ect_at_school_period:,
                school_partnership: school_partnership_2024,
                started_on: previous_training_period_finished_on + 1.day,
                finished_on: second_training_period_finished_on
              )
            end

            let!(:training_period) do
              FactoryBot.create(
                :training_period,
                :for_ect,
                :ongoing,
                :school_led,
                ect_at_school_period:,
                started_on: second_training_period_finished_on + 1.day
              )
            end

            it "finishes the existing training period" do
              SwitchTraining.to_provider_led(ect_at_school_period, lead_provider:, author:)

              expect { training_period.reload }.not_to raise_error
              expect(training_period.finished_on).to eq(Date.current)
            end

            it "retains the schedule from the open contract period" do
              SwitchTraining.to_provider_led(ect_at_school_period, lead_provider:, author:)

              new_training_period = ect_at_school_period.reload.training_periods.last
              schedule = new_training_period.schedule
              expect(schedule).to eq(second_training_period.schedule)
              expect(schedule.contract_period).to eq(contract_period_2024)
            end

            it "does not set the ECT's payments frozen year" do
              expect {
                SwitchTraining.to_provider_led(ect_at_school_period, lead_provider:, author:)
              }.not_to change(ect_at_school_period.teacher, :ect_payments_frozen_year)
            end
          end
        end

        context "when there is no confirmed school partnership" do
          let!(:previous_training_period) do
            FactoryBot.create(
              :training_period,
              :for_ect,
              :provider_led,
              :with_only_expression_of_interest,
              ect_at_school_period:,
              expression_of_interest: active_lead_provider,
              started_on:,
              finished_on: previous_training_period_finished_on
            )
          end

          let!(:training_period) do
            FactoryBot.create(
              :training_period,
              :for_ect,
              :ongoing,
              :school_led,
              ect_at_school_period:,
              started_on: previous_training_period_finished_on + 1.day
            )
          end

          context "when there is one previous provider-led training period" do
            context "when the earlier contract period is open" do
              let(:started_on) { Date.new(2024, 6, 1) }
              let(:contract_period) { contract_period_2024 }
              let(:previous_training_period_finished_on) { 2.months.ago }

              it "finishes the existing training period" do
                SwitchTraining.to_provider_led(ect_at_school_period, lead_provider:, author:)

                expect { training_period.reload }.not_to raise_error
                expect(training_period.finished_on).to eq(Date.current)
              end

              it "retains the previous schedule and contract period" do
                SwitchTraining.to_provider_led(ect_at_school_period, lead_provider:, author:)

                new_training_period = ect_at_school_period.reload.training_periods.last
                schedule = new_training_period.schedule
                expect(schedule).to eq(previous_training_period.schedule)
                expect(schedule.contract_period).to eq(contract_period_2024)
              end

              it "does not set the ECT's payments frozen year" do
                expect {
                  SwitchTraining.to_provider_led(ect_at_school_period, lead_provider:, author:)
                }.not_to change(ect_at_school_period.teacher, :ect_payments_frozen_year)
              end
            end

            context "when the earlier contract period is closed" do
              let(:started_on) { Date.new(2021, 9, 1) }
              let(:previous_training_period_finished_on) { Date.new(2021, 10, 31) }
              let(:contract_period) { contract_period_2021 }

              before do
                FactoryBot.create(:active_lead_provider, :for_year, year: 2024, lead_provider:)
              end

              it "finishes the existing training period" do
                SwitchTraining.to_provider_led(ect_at_school_period, lead_provider:, author:)

                expect { training_period.reload }.not_to raise_error
                expect(training_period.finished_on).to eq(Date.current)
              end

              it "moves to the successor contract period with an extended schedule" do
                SwitchTraining.to_provider_led(ect_at_school_period, lead_provider:, author:)

                expect(ect_at_school_period.reload).to be_provider_led_training_programme
                new_training_period = ect_at_school_period.reload.training_periods.last
                schedule = new_training_period.schedule
                expect(schedule.contract_period).to eq(contract_period_2024)
                expect(schedule.identifier).to eq("ecf-extended-september")
              end

              it "sets the ECT's payments frozen year to 2021" do
                expect {
                  SwitchTraining.to_provider_led(ect_at_school_period, lead_provider:, author:)
                }.to change(ect_at_school_period.teacher, :ect_payments_frozen_year).from(nil).to(2021)
              end
            end
          end

          context "when there are two previous provider-led training periods" do
            let(:started_on) { Date.new(2021, 9, 1) }
            let(:previous_training_period_finished_on) { Date.new(2024, 9, 1) }
            let(:second_training_period_finished_on) { 1.month.ago }
            let(:contract_period) { contract_period_2021 }
            let(:expression_of_interest) { FactoryBot.create(:active_lead_provider, :for_year, year: 2024, lead_provider:) }

            let!(:second_training_period) do
              FactoryBot.create(
                :training_period,
                :for_ect,
                :provider_led,
                :with_only_expression_of_interest,
                ect_at_school_period:,
                expression_of_interest:,
                started_on: previous_training_period_finished_on + 1.day,
                finished_on: second_training_period_finished_on
              )
            end

            let!(:training_period) do
              FactoryBot.create(
                :training_period,
                :for_ect,
                :ongoing,
                :school_led,
                ect_at_school_period:,
                started_on: second_training_period_finished_on + 1.day
              )
            end

            it "finishes the existing training period" do
              SwitchTraining.to_provider_led(ect_at_school_period, lead_provider:, author:)

              expect { training_period.reload }.not_to raise_error
              expect(training_period.finished_on).to eq(Date.current)
            end

            it "retains the schedule from the open contract period" do
              SwitchTraining.to_provider_led(ect_at_school_period, lead_provider:, author:)

              new_training_period = ect_at_school_period.reload.training_periods.last
              schedule = new_training_period.schedule
              expect(schedule).to eq(second_training_period.schedule)
              expect(schedule.contract_period).to eq(contract_period_2024)
            end

            it "does not set the ECT's payments frozen year" do
              expect {
                SwitchTraining.to_provider_led(ect_at_school_period, lead_provider:, author:)
              }.not_to change(ect_at_school_period.teacher, :ect_payments_frozen_year)
            end
          end
        end
      end

      context "when there is no `current_or_next_training_period`" do
        before do
          allow(ect_at_school_period).to receive(:current_or_next_training_period).and_return(nil)
        end

        it "creates a new provider-led training period (with expression of interest if no partnership)" do
          expect {
            SwitchTraining.to_provider_led(ect_at_school_period, lead_provider:, author:)
          }.to change(TrainingPeriod, :count).by(2)

          ect_at_school_period_from_database = ECTAtSchoolPeriod.find(ect_at_school_period.id)

          expect(ect_at_school_period_from_database).to be_provider_led_training_programme

          new_ect_training_period = ect_at_school_period_from_database.training_periods.last
          expect(new_ect_training_period.school_partnership).to be_nil
          expect(new_ect_training_period.expression_of_interest).to eq(active_lead_provider)
        end
      end

      context "when there is no `current_or_next_training_period` and no lead_provider provided" do
        before do
          allow(ect_at_school_period).to receive(:current_or_next_training_period).and_return(nil)
        end

        it "raises an error" do
          expect { SwitchTraining.to_provider_led(ect_at_school_period, lead_provider: nil, author:) }
            .to raise_error(NoTrainingPeriodError)
        end
      end

      context "when the `ECTAtSchoolPeriod` has a `finished_on` date" do
        let(:ect_at_school_period) do
          FactoryBot.create(
            :ect_at_school_period,
            started_on: 2.weeks.ago,
            finished_on: 6.months.from_now
          )
        end

        it "creates a training period that finishes on the same date" do
          SwitchTraining.to_provider_led(ect_at_school_period, lead_provider:, author:)

          new_training_period = ect_at_school_period.reload.latest_training_period
          expect(new_training_period).not_to be_ongoing
          expect(new_training_period.finished_on).to eq(ect_at_school_period.finished_on)
        end
      end

      context "when the `ECTAtSchoolPeriod` does not have a `finished_on` date" do
        let(:ect_at_school_period) do
          FactoryBot.create(:ect_at_school_period, :ongoing)
        end

        it "creates an ongoing training period" do
          SwitchTraining.to_provider_led(ect_at_school_period, lead_provider:, author:)

          new_training_period = ect_at_school_period.reload.latest_training_period
          expect(new_training_period).to be_ongoing
        end
      end

      context "when the record is not a `ECTAtSchoolPeriod`" do
        let(:ect_at_school_period) do
          FactoryBot.create(:mentor_at_school_period, :ongoing)
        end

        let(:mentorship_period) { nil }

        it "raises an error" do
          expect { SwitchTraining.to_provider_led(ect_at_school_period, lead_provider:, author:) }
            .to raise_error(ArgumentError)
        end
      end

      context "for mentors" do
        let!(:training_period) do
          FactoryBot.create(
            :training_period,
            :for_ect,
            :ongoing,
            :school_led,
            ect_at_school_period:,
            started_on: ect_at_school_period.started_on
          )
        end

        context "when the mentor has never had provider-led training" do
          context "when there is no confirmed school partnership" do
            it "assigns the mentor to the same lead provider with an expression of interest" do
              expect { SwitchTraining.to_provider_led(ect_at_school_period, lead_provider:, author:) }
                .to change(TrainingPeriod, :count).by(2)

              expect(mentor_at_school_period.reload).to be_provider_led_training_programme
              new_training_period = mentor_at_school_period.training_periods.last
              expect(new_training_period.school_partnership).to be_nil
              expect(new_training_period.expression_of_interest).to eq(active_lead_provider)
              expect(new_training_period.started_on).to eq(Date.current)
              expect(new_training_period.schedule.contract_period.year).to eq(contract_period.year)
            end

            it "records a `new_training_period_for_mentor` event" do
              freeze_time

              allow(Events::Record).to receive(:record_teacher_starts_training_period_event!)

              SwitchTraining.to_provider_led(ect_at_school_period, lead_provider:, author:)

              new_training_period = mentor_at_school_period.reload.training_periods.last

              expect(Events::Record)
                .to have_received(:record_teacher_starts_training_period_event!)
                .with(
                  school: ect_at_school_period.school,
                  teacher: mentor_at_school_period.teacher,
                  training_period: new_training_period,
                  mentor_at_school_period:,
                  ect_at_school_period: nil,
                  author:,
                  happened_at: Time.current
                )
            end

            context "when the switch happens on the last day of the current contract period" do
              around do |example|
                travel_to(Date.new(2025, 5, 31)) do
                  example.run
                end
              end

              it "finds the active lead provider with the correct contract period" do
                SwitchTraining.to_provider_led(ect_at_school_period, lead_provider:, author:)

                new_training_period = mentor_at_school_period.training_periods.last
                expect(new_training_period.expression_of_interest).to eq(active_lead_provider)
              end
            end
          end

          context "when there is a confirmed school partnership" do
            let!(:lead_provider_delivery_partnership) do
              FactoryBot.create(
                :lead_provider_delivery_partnership,
                active_lead_provider:
              )
            end
            let!(:school_partnership) do
              FactoryBot.create(
                :school_partnership,
                lead_provider_delivery_partnership:,
                school: ect_at_school_period.school
              )
            end

            it "assigns the mentor to the same lead provider" do
              expect { SwitchTraining.to_provider_led(ect_at_school_period, lead_provider:, author:) }
                .to change(TrainingPeriod, :count).by(2)

              expect(mentor_at_school_period.reload).to be_provider_led_training_programme
              new_training_period = mentor_at_school_period.training_periods.last
              expect(new_training_period.school_partnership).to eq(school_partnership)
              expect(new_training_period.expression_of_interest).to be_nil
              expect(new_training_period.started_on).to eq(Date.current)
              expect(new_training_period.schedule.contract_period.year).to eq(contract_period.year)
            end

            context "when the switch happens on the last day of the current contract period" do
              around do |example|
                travel_to(Date.new(2025, 5, 31)) do
                  example.run
                end
              end

              it "finds the existing lead provider" do
                SwitchTraining.to_provider_led(ect_at_school_period, lead_provider:, author:)

                new_training_period = mentor_at_school_period.training_periods.last
                expect(new_training_period.school_partnership).to eq(school_partnership)
              end
            end
          end

          context "assigning the schedule based on the current date" do
            let!(:contract_period) do
              FactoryBot.create(:contract_period, :with_schedules, year: 2025)
            end

            context "when the switch happens between November and February" do
              around do |example|
                travel_to(Date.new(2025, 11, 15)) do
                  example.run
                end
              end

              it "assigns a January schedule" do
                SwitchTraining.to_provider_led(ect_at_school_period, lead_provider:, author:)

                new_training_period = mentor_at_school_period.training_periods.last
                expect(new_training_period.schedule.identifier).to eq("ecf-standard-january")
                expect(new_training_period.schedule.contract_period.year).to eq(2025)
              end
            end

            context "when the switch happens between June and October" do
              around do |example|
                travel_to(Date.new(2025, 9, 15)) do
                  example.run
                end
              end

              it "assigns a September schedule" do
                SwitchTraining.to_provider_led(ect_at_school_period, lead_provider:, author:)

                new_training_period = mentor_at_school_period.training_periods.last
                expect(new_training_period.schedule.identifier).to eq("ecf-standard-september")
                expect(new_training_period.schedule.contract_period.year).to eq(2025)
              end
            end

            context "when the switch happens between March and June" do
              around do |example|
                travel_to(Date.new(2026, 5, 15)) do
                  example.run
                end
              end

              it "assigns an April schedule" do
                SwitchTraining.to_provider_led(ect_at_school_period, lead_provider:, author:)

                new_training_period = mentor_at_school_period.training_periods.last
                expect(new_training_period.schedule.identifier).to eq("ecf-standard-april")
                expect(new_training_period.schedule.contract_period.year).to eq(2025)
              end
            end
          end

          context "when the mentor is leaving the school" do
            let(:mentor_at_school_period) do
              FactoryBot.create(
                :mentor_at_school_period,
                started_on: ect_at_school_period.started_on,
                finished_on: ect_at_school_period.started_on.advance(years: 1),
                school: ect_at_school_period.school
              )
            end

            it "assigns a `finished_on` date for the training period" do
              SwitchTraining.to_provider_led(ect_at_school_period, lead_provider:, author:)

              new_training_period = mentor_at_school_period.training_periods.last
              expect(new_training_period.finished_on).to eq(mentor_at_school_period.finished_on)
            end
          end
        end

        context "when the mentor has had provider-led training before" do
          let!(:previous_training_period) do
            FactoryBot.create(:training_period, :for_mentor, :provider_led, mentor_at_school_period:)
          end

          it "does not create a new training period for the mentor" do
            expect { SwitchTraining.to_provider_led(ect_at_school_period, lead_provider:, author:) }
              .to change(TrainingPeriod, :count).by(1)

            expect(TrainingPeriod.where(mentor_at_school_period:)).to contain_exactly(previous_training_period)
          end

          it "does not record a `new_training_period_for_mentor` event" do
            expect(Events::Record)
              .not_to receive(:record_teacher_starts_training_period_event!)

            SwitchTraining.to_provider_led(ect_at_school_period, lead_provider:, author:)
          end
        end

        context "when the mentor is ineligible for funding" do
          let(:teacher) { FactoryBot.create(:teacher, :ineligible_for_mentor_funding) }
          let(:mentor_at_school_period) do
            FactoryBot.create(
              :mentor_at_school_period,
              :ongoing,
              school: ect_at_school_period.school,
              teacher:,
              started_on: ect_at_school_period.started_on
            )
          end

          it "does not create a new training period for the mentor" do
            SwitchTraining.to_provider_led(ect_at_school_period, lead_provider:, author:)

            expect(mentor_at_school_period.training_periods).to be_empty
          end

          it "does not record a `new_training_period_for_mentor` event" do
            expect(Events::Record)
              .not_to receive(:record_teacher_starts_training_period_event!)

            SwitchTraining.to_provider_led(ect_at_school_period, lead_provider:, author:)
          end
        end

        context "when the mentee has no mentor" do
          let(:mentorship_period) { nil }

          it "does not create a new training period for the mentor" do
            expect { SwitchTraining.to_provider_led(ect_at_school_period, lead_provider:, author:) }
              .to change(TrainingPeriod, :count).by(1)

            expect(mentor_at_school_period.training_periods).to be_empty
          end

          it "does not record a `new_training_period_for_mentor` event" do
            expect(Events::Record)
              .not_to receive(:record_teacher_starts_training_period_event!)

            SwitchTraining.to_provider_led(ect_at_school_period, lead_provider:, author:)
          end
        end
      end
    end
  end
end
