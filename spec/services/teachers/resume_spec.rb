RSpec.describe Teachers::Resume do
  let(:author) { Events::LeadProviderAPIAuthor.new(lead_provider:) }
  let(:lead_provider) { training_period.lead_provider }
  let(:teacher) { training_period.trainee.teacher }

  let(:service) do
    described_class.new(
      author:,
      lead_provider:,
      teacher:,
      training_period:
    )
  end

  describe "#resume" do
    %i[ect mentor].each do |trainee_type|
      context "for #{trainee_type}" do
        let(:at_school_period) { FactoryBot.create(:"#{trainee_type}_at_school_period", :ongoing, started_on: 6.months.ago) }
        let(:course_identifier) { trainee_type == :ect ? "ecf-induction" : "ecf-mentor" }

        context "when training period is active" do
          let!(:training_period) { FactoryBot.create(:training_period, :"for_#{trainee_type}", :ongoing, "#{trainee_type}_at_school_period": at_school_period, started_on: at_school_period.started_on) }

          it "raises an error" do
            expect {
              service.resume
            }.to raise_error(ActiveRecord::RecordInvalid, /Validation failed: Started on Start date cannot overlap another Trainee period/)
          end
        end

        context "when teacher has moved to a new Lead provider" do
          let(:teacher) { FactoryBot.create(:teacher) }
          let(:at_school_period) { FactoryBot.create(:"#{trainee_type}_at_school_period", started_on: 6.months.ago, finished_on: 5.months.ago, teacher:) }
          let(:at_school_period_new) { FactoryBot.create(:"#{trainee_type}_at_school_period", :ongoing, started_on: 4.months.ago, finished_on: nil, teacher:) }
          let!(:training_period) { FactoryBot.create(:training_period, :"for_#{trainee_type}", :deferred, "#{trainee_type}_at_school_period": at_school_period, started_on: at_school_period.started_on, finished_on: at_school_period.finished_on) }
          let!(:training_period_new) { FactoryBot.create(:training_period, :"for_#{trainee_type}", :ongoing, "#{trainee_type}_at_school_period": at_school_period_new, started_on: at_school_period_new.started_on, finished_on: nil) }

          it "raises an error" do
            expect {
              service.resume
            }.to raise_error(ActiveRecord::StatementInvalid, /range lower bound must be less than or equal to range upper bound/)
          end
        end

        context "when teacher is deferred and remaining at a school" do
          let!(:training_period) { FactoryBot.create(:training_period, :"for_#{trainee_type}", :deferred, "#{trainee_type}_at_school_period": at_school_period, started_on: at_school_period.started_on) }

          it "resumes training period" do
            freeze_time

            expect {
              service.resume
            }.to change(TrainingPeriod, :count).by(1)

            created_training_period = TrainingPeriod.last
            expect(created_training_period).to be_ongoing
            expect(created_training_period.deferred_at).to be_nil
            expect(created_training_period.trainee).to eq(training_period.trainee)
            expect(created_training_period.started_on).to eq(Time.zone.today)
            expect(created_training_period.finished_on).to eq(training_period.trainee.finished_on)
            expect(created_training_period.school_partnership).to eq(training_period.school_partnership)
            expect(created_training_period.expression_of_interest).to eq(training_period.expression_of_interest)
            expect(created_training_period.schedule).to eq(training_period.schedule)
          end
        end

        context "when teacher is deferred and leaving a school" do
          let(:at_school_period) { FactoryBot.create(:"#{trainee_type}_at_school_period", started_on: 6.months.ago, finished_on: 5.months.from_now) }
          let!(:training_period) { FactoryBot.create(:training_period, :"for_#{trainee_type}", :deferred, "#{trainee_type}_at_school_period": at_school_period, started_on: at_school_period.started_on, finished_on: 1.month.ago) }

          it "resumes training period" do
            freeze_time

            expect {
              service.resume
            }.to change(TrainingPeriod, :count).by(1)

            created_training_period = TrainingPeriod.last
            expect(created_training_period.finished_on).to eq(at_school_period.finished_on)
            expect(created_training_period.deferred_at).to be_nil
            expect(created_training_period.trainee).to eq(training_period.trainee)
            expect(created_training_period.started_on).to eq(Time.zone.today)
            expect(created_training_period.finished_on).to eq(training_period.trainee.finished_on)
            expect(created_training_period.school_partnership).to eq(training_period.school_partnership)
            expect(created_training_period.expression_of_interest).to eq(training_period.expression_of_interest)
            expect(created_training_period.schedule).to eq(training_period.schedule)
          end
        end

        context "when teacher is withdrawn and remaining at a school" do
          let!(:training_period) { FactoryBot.create(:training_period, :"for_#{trainee_type}", :withdrawn, "#{trainee_type}_at_school_period": at_school_period, started_on: at_school_period.started_on) }

          it "resumes training period" do
            freeze_time

            expect {
              service.resume
            }.to change(TrainingPeriod, :count).by(1)

            created_training_period = TrainingPeriod.last
            expect(created_training_period).to be_ongoing
            expect(created_training_period.withdrawn_at).to be_nil
            expect(created_training_period.trainee).to eq(training_period.trainee)
            expect(created_training_period.started_on).to eq(Time.zone.today)
            expect(created_training_period.finished_on).to eq(training_period.trainee.finished_on)
            expect(created_training_period.school_partnership).to eq(training_period.school_partnership)
            expect(created_training_period.expression_of_interest).to eq(training_period.expression_of_interest)
            expect(created_training_period.schedule).to eq(training_period.schedule)
          end
        end

        context "when teacher is withdrawn and leaving a school" do
          let(:at_school_period) { FactoryBot.create(:"#{trainee_type}_at_school_period", started_on: 6.months.ago, finished_on: 5.months.from_now) }
          let!(:training_period) { FactoryBot.create(:training_period, :"for_#{trainee_type}", :withdrawn, "#{trainee_type}_at_school_period": at_school_period, started_on: at_school_period.started_on, finished_on: 1.month.ago) }

          it "resumes training period" do
            freeze_time

            expect {
              service.resume
            }.to change(TrainingPeriod, :count).by(1)

            created_training_period = TrainingPeriod.last
            expect(created_training_period.finished_on).to eq(at_school_period.finished_on)
            expect(created_training_period.withdrawn_at).to be_nil
            expect(created_training_period.trainee).to eq(training_period.trainee)
            expect(created_training_period.started_on).to eq(Time.zone.today)
            expect(created_training_period.finished_on).to eq(training_period.trainee.finished_on)
            expect(created_training_period.school_partnership).to eq(training_period.school_partnership)
            expect(created_training_period.expression_of_interest).to eq(training_period.expression_of_interest)
            expect(created_training_period.schedule).to eq(training_period.schedule)
          end
        end

        context "when teacher is moving to a new Lead provider" do
          let(:teacher) { FactoryBot.create(:teacher) }
          let(:at_school_period) { FactoryBot.create(:"#{trainee_type}_at_school_period", started_on: 6.months.ago, finished_on: 2.months.from_now, teacher:) }
          let(:at_school_period_new) { FactoryBot.create(:"#{trainee_type}_at_school_period", :ongoing, started_on: 2.months.from_now, finished_on: nil, teacher:) }
          let!(:training_period) { FactoryBot.create(:training_period, :"for_#{trainee_type}", :deferred, "#{trainee_type}_at_school_period": at_school_period, started_on: at_school_period.started_on, finished_on: 1.month.ago) }
          let!(:training_period_new) { FactoryBot.build(:training_period, :"for_#{trainee_type}", :ongoing, "#{trainee_type}_at_school_period": at_school_period_new, started_on: at_school_period_new.started_on, finished_on: nil) }

          it "resumes training period" do
            freeze_time

            expect {
              service.resume
            }.to change(TrainingPeriod, :count).by(1)

            created_training_period = TrainingPeriod.last
            expect(created_training_period.finished_on).to eq(training_period_new.started_on)
            expect(created_training_period.withdrawn_at).to be_nil
            expect(created_training_period.trainee).to eq(training_period.trainee)
            expect(created_training_period.started_on).to eq(Time.zone.today)
            expect(created_training_period.finished_on).to eq(training_period.trainee.finished_on)
            expect(created_training_period.school_partnership).to eq(training_period.school_partnership)
            expect(created_training_period.expression_of_interest).to eq(training_period.expression_of_interest)
            expect(created_training_period.schedule).to eq(training_period.schedule)
          end
        end

        context "event recording" do
          let!(:training_period) { FactoryBot.create(:training_period, :"for_#{trainee_type}", :withdrawn, "#{trainee_type}_at_school_period": at_school_period, started_on: at_school_period.started_on) }

          it "records a teacher resumes training period event" do
            freeze_time do
              allow(Events::Record).to receive(:record_teacher_training_period_resumed_event!)

              service.resume

              expect(Events::Record).to have_received(:record_teacher_training_period_resumed_event!)
                .with(author:, teacher:, lead_provider:, training_period:, metadata: { new_training_period_id: TrainingPeriod.last.id })
            end
          end
        end
      end
    end
  end
end
