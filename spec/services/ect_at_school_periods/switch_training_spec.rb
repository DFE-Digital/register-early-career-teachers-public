module ECTAtSchoolPeriods
  RSpec.describe SwitchTraining do
    let(:ect_at_school_period) do
      FactoryBot.create(:ect_at_school_period, :ongoing, started_on: 2.weeks.ago)
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

        it "raises an error" do
          expect { SwitchTraining.to_school_led(ect_at_school_period, author:) }
            .to raise_error(ArgumentError)
        end
      end
    end

    describe ".to_provider_led" do
      let!(:contract_period) do
        FactoryBot.create(:contract_period, :with_schedules, year: Date.current.year)
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

        it "raises an error" do
          expect { SwitchTraining.to_provider_led(ect_at_school_period, lead_provider:, author:) }
            .to raise_error(ArgumentError)
        end
      end
    end
  end
end
