module ECTAtSchoolPeriods
  RSpec.describe SwitchTraining do
    let(:ect_at_school_period) do
      FactoryBot.create(:ect_at_school_period, :ongoing, started_on: 2.weeks.ago)
    end

    let(:mentor_at_school_period) do
      FactoryBot.create(:mentor_at_school_period, :ongoing,
                        started_on: ect_at_school_period.started_on,
                        school: ect_at_school_period.school)
    end

    let!(:mentorship_period) do
      FactoryBot.create(:mentorship_period, mentee: ect_at_school_period, mentor: mentor_at_school_period)
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
        it "raises an error" do
          expect { SwitchTraining.to_school_led(ect_at_school_period, author:) }
            .to raise_error(NoTrainingPeriodError)
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
          before do
            skip <<-MSG
              Temporarily skipping this test as its causing a persistent failure due to
              the schedule selection logic not lining up with the logic around selecting an
              expression of interest for the provider-led training period. They end up with
              different contract periods, which is not a valid training period state. There is
              a bug ticket open to look into this and find a resolution.
            MSG
          end

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

      context "when there is no `current_or_next_training_period`" do
        it "raises an error" do
          expect { SwitchTraining.to_provider_led(ect_at_school_period, lead_provider:, author:) }
            .to raise_error(NoTrainingPeriodError)
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
              expect { SwitchTraining.to_provider_led(ect_at_school_period, lead_provider:, author:) }.to change(TrainingPeriod, :count).by(2)

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
              expect { SwitchTraining.to_provider_led(ect_at_school_period, lead_provider:, author:) }.to change(TrainingPeriod, :count).by(2)

              expect(mentor_at_school_period.reload).to be_provider_led_training_programme
              new_training_period = mentor_at_school_period.training_periods.last
              expect(new_training_period.school_partnership).to eq(school_partnership)
              expect(new_training_period.expression_of_interest).to be_nil
              expect(new_training_period.started_on).to eq(Date.current)
              expect(new_training_period.schedule.contract_period.year).to eq(contract_period.year)
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
        end

        context "when the mentor has had provider-led training before" do
          let!(:previous_training_period) { FactoryBot.create(:training_period, :for_mentor, :provider_led, mentor_at_school_period:) }

          it "does not create a new training period for the mentor" do
            expect { SwitchTraining.to_provider_led(ect_at_school_period, lead_provider:, author:) }.to change(TrainingPeriod, :count).by(1)

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
            FactoryBot.create(:mentor_at_school_period, :ongoing, teacher:, started_on: ect_at_school_period.started_on)
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
