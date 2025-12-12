RSpec.describe Teachers::ChangeSchedule do
  let(:lead_provider) { training_period.lead_provider }
  let(:teacher) { training_period.trainee.teacher }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:, contract_period: new_contract_period) }
  let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:) }
  let(:new_contract_period) { FactoryBot.create(:contract_period) }
  let!(:new_school_partnership) { FactoryBot.create(:school_partnership, school: at_school_period.school, lead_provider_delivery_partnership:) }
  let(:new_schedule) { FactoryBot.create(:schedule, identifier: "ecf-standard-april", contract_period: new_contract_period) }
  let(:author) { Events::LeadProviderAPIAuthor.new(lead_provider:) }

  let(:service) do
    described_class.new(
      author:,
      lead_provider:,
      teacher:,
      training_period:,
      schedule: new_schedule,
      school_partnership: new_school_partnership
    )
  end

  describe "#change_schedule" do
    %i[ect mentor].each do |trainee_type|
      context "for #{trainee_type}" do
        let(:at_school_period) { FactoryBot.create(:"#{trainee_type}_at_school_period", :ongoing, started_on: school_period_started_on, finished_on: school_period_finished_on) }
        let!(:training_period) { FactoryBot.create(:training_period, :"for_#{trainee_type}", :ongoing, :with_expression_of_interest, "#{trainee_type}_at_school_period": at_school_period, started_on: at_school_period.started_on, finished_on: training_period_finished_on) }
        let!(:school_period_started_on) { 6.months.ago }
        let(:school_period_finished_on) { nil }
        let(:training_period_finished_on) { nil }

        it "ends the current training period and creates a new training period starting today with the new schedule/partnership/contract period" do
          expect { service.change_schedule }.to change(TrainingPeriod, :count).from(1).to(2)

          expect(training_period.reload.finished_on).to eq(Time.zone.today)

          new_training_period = TrainingPeriod.except(training_period).last

          expect(training_period.school_partnership).not_to eq(new_training_period.school_partnership)
          expect(training_period.contract_period.year).not_to eq(new_training_period.contract_period.year)

          expect(new_training_period.trainee).to eq(at_school_period)
          expect(new_training_period.started_on).to eq(Time.zone.today)
          expect(new_training_period.finished_on).to be_nil
          expect(new_training_period.schedule).to eq(new_schedule)
          expect(new_training_period.school_partnership).to eq(new_school_partnership)
          expect(new_training_period.contract_period).to eq(new_contract_period)
          expect(new_training_period.expression_of_interest).to be_nil
        end

        context "when the existing training_period.finished_on and school_period.finished_on are nil" do
          let(:school_period_finished_on) { nil }
          let(:training_period_finished_on) { nil }

          it "sets the newly created training period finished_on to nil" do
            expect { service.change_schedule }.to change(TrainingPeriod, :count).from(1).to(2)

            expect(training_period.reload.finished_on).to eq(Time.zone.today)

            new_training_period = TrainingPeriod.except(training_period).last
            expect(new_training_period.finished_on).to be_nil
          end
        end

        context "when the existing training_period.finished_on is set to the future" do
          let(:school_period_finished_on) { nil }
          let(:training_period_finished_on) { 3.days.from_now.to_date }

          it "retains the original finished_on for the newly created training period" do
            expect { service.change_schedule }.to change(TrainingPeriod, :count).from(1).to(2)

            expect(training_period.reload.finished_on).to eq(Time.zone.today)

            new_training_period = TrainingPeriod.except(training_period).last
            expect(new_training_period.finished_on).to eq(training_period_finished_on)
          end
        end

        context "when the existing training_period.finished_on and school_period.finished_on are set to the future" do
          let(:school_period_finished_on) { 3.days.from_now.to_date }
          let(:training_period_finished_on) { school_period_finished_on }

          it "retains the original finished_on for the newly created training period" do
            expect { service.change_schedule }.to change(TrainingPeriod, :count).from(1).to(2)

            expect(training_period.reload.finished_on).to eq(Time.zone.today)

            new_training_period = TrainingPeriod.except(training_period).last
            expect(new_training_period.finished_on).to eq(school_period_finished_on)
          end
        end

        context "event recording" do
          it "records a teacher changes schedule training period event" do
            freeze_time do
              allow(Events::Record).to receive(:record_teacher_schedule_changed_event!)

              service.change_schedule

              expect(Events::Record).to have_received(:record_teacher_schedule_changed_event!)
                .with(author:,
                      teacher:,
                      lead_provider:,
                      original_training_period: training_period,
                      original_schedule: training_period.schedule,
                      new_training_period: TrainingPeriod.last)
            end
          end
        end

        context "when moving away from a frozen contract period" do
          let(:contract_period) { training_period.contract_period }

          before { contract_period.update!(payments_frozen_at: Time.zone.now) }

          it "updates `#{trainee_type}_payments_frozen_year` value accordingly" do
            service.change_schedule

            expect(teacher.reload.public_send("#{trainee_type}_payments_frozen_year")).to eq(contract_period.year)
          end
        end

        context "when moving back to a frozen contract period" do
          let(:new_contract_period) { FactoryBot.create(:contract_period, :with_payments_frozen, year: training_period.contract_period.year + 1) }
          let!(:school_partnership) { FactoryBot.create(:school_partnership, :for_year, year: new_contract_period.year, lead_provider:, school: training_period.school_partnership.school) }

          before { teacher.update!("#{trainee_type}_payments_frozen_year": new_contract_period.year) }

          it "resets `#{trainee_type}_payments_frozen_year` value" do
            service.change_schedule

            expect(teacher.reload.public_send("#{trainee_type}_payments_frozen_year")).to be_nil
          end
        end

        context "when the existing training_period.started_on has not yet passed" do
          let(:school_period_started_on) { Time.zone.today }

          it "updates the existing training period with the new schedule/partnership/contract period" do
            expect { service.change_schedule }.not_to change(TrainingPeriod, :count)

            expect(training_period.trainee).to eq(at_school_period)
            expect(training_period.started_on).to eq(school_period_started_on)
            expect(training_period.finished_on).to be_nil
            expect(training_period.schedule).to eq(new_schedule)
            expect(training_period.school_partnership).to eq(new_school_partnership)
            expect(training_period.contract_period).to eq(new_contract_period)
            expect(training_period.expression_of_interest).to eq(new_school_partnership.active_lead_provider)
          end
        end
      end
    end
  end
end
