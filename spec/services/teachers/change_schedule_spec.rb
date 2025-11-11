RSpec.describe Teachers::ChangeSchedule do
  let(:lead_provider) { training_period.lead_provider }
  let(:teacher) { training_period.trainee.teacher }
  let(:school_partnership) { training_period.school_partnership }
  let(:contract_period) { training_period.contract_period }
  let(:schedule) { FactoryBot.create(:schedule, identifier: "ecf-standard-april", contract_period_year: contract_period.year) }

  let(:service) do
    described_class.new(
      lead_provider:,
      teacher:,
      training_period:,
      schedule:,
      school_partnership:
    )
  end

  describe "#change_schedule" do
    %i[ect mentor].each do |trainee_type|
      context "for #{trainee_type}" do
        let(:at_school_period) { FactoryBot.create(:"#{trainee_type}_at_school_period", :ongoing, started_on: 6.months.ago) }
        let!(:training_period) { FactoryBot.create(:training_period, :"for_#{trainee_type}", :ongoing, "#{trainee_type}_at_school_period": at_school_period, started_on: at_school_period.started_on, finished_on:) }
        let(:finished_on) { nil }

        context "when changing schedule only" do
          it "changes schedule" do
            expect(TrainingPeriod.count).to eq(1)

            service.change_schedule

            expect(TrainingPeriod.count).to eq(2)
            training_period.reload
            expect(training_period.finished_on).to eq(Time.zone.today)

            new_training_period = TrainingPeriod.except(training_period).last
            expect(new_training_period.trainee).to eq(at_school_period)
            expect(new_training_period.started_on).to eq(Time.zone.today)
            expect(new_training_period.schedule).to eq(schedule)
            expect(new_training_period.school_partnership).to eq(school_partnership)
            expect(new_training_period.contract_period).to eq(contract_period)
          end

          context "when existing training_period.finished_on is set in the future" do
            let(:finished_on) { 3.days.from_now.to_date }

            it "changes schedule without changing finished_on" do
              expect(TrainingPeriod.count).to eq(1)

              service.change_schedule

              expect(TrainingPeriod.count).to eq(2)
              training_period.reload
              expect(training_period.finished_on).to eq(finished_on)

              new_training_period = TrainingPeriod.except(training_period).last
              expect(new_training_period.trainee).to eq(at_school_period)
              expect(new_training_period.started_on).to eq(finished_on)
              expect(new_training_period.schedule).to eq(schedule)
              expect(new_training_period.school_partnership).to eq(school_partnership)
              expect(new_training_period.contract_period).to eq(contract_period)
            end
          end

          context "when existing training_period.finished_on is set in the past" do
            let(:finished_on) { 10.days.ago.to_date }

            it "changes schedule without changing finished_on" do
              expect(TrainingPeriod.count).to eq(1)

              service.change_schedule

              expect(TrainingPeriod.count).to eq(2)
              training_period.reload
              expect(training_period.finished_on).to eq(finished_on)

              new_training_period = TrainingPeriod.except(training_period).last
              expect(new_training_period.trainee).to eq(at_school_period)
              expect(new_training_period.started_on).to eq(Time.zone.today)
              expect(new_training_period.schedule).to eq(schedule)
              expect(new_training_period.school_partnership).to eq(school_partnership)
              expect(new_training_period.contract_period).to eq(contract_period)
            end
          end
        end

        context "when changing schedule and school_partnership" do
          let(:contract_period) { FactoryBot.create(:contract_period) }
          let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:, contract_period:) }
          let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:) }
          let!(:school_partnership) { FactoryBot.create(:school_partnership, school: at_school_period.school, lead_provider_delivery_partnership:) }
          let!(:schedule) { FactoryBot.create(:schedule, identifier: "ecf-standard-april", contract_period_year: contract_period.year) }

          it "changes schedule" do
            expect(TrainingPeriod.count).to eq(1)

            service.change_schedule

            expect(TrainingPeriod.count).to eq(2)
            training_period.reload
            expect(training_period.finished_on).to eq(Time.zone.today)

            new_training_period = TrainingPeriod.except(training_period).last
            expect(new_training_period.trainee).to eq(at_school_period)
            expect(new_training_period.started_on).to eq(Time.zone.today)
            expect(new_training_period.schedule).to eq(schedule)
            expect(new_training_period.school_partnership).to eq(school_partnership)
            expect(new_training_period.contract_period).to eq(contract_period)
            expect(new_training_period.lead_provider).to eq(lead_provider)
          end
        end

        context "event recording" do
          let(:author) { Events::LeadProviderAPIAuthor.new(lead_provider:) }

          before do
            allow(Events::LeadProviderAPIAuthor).to receive(:new).and_return(author)
          end

          it "records a teacher changes schedule training period event" do
            freeze_time do
              allow(Events::Record).to receive(:record_teacher_training_period_change_schedule_event!)

              service.change_schedule

              expect(Events::Record).to have_received(:record_teacher_training_period_change_schedule_event!)
                .with(author:, teacher:, lead_provider:, training_period:, metadata: { new_training_period_id: TrainingPeriod.last.id })
            end
          end
        end
      end
    end
  end
end
