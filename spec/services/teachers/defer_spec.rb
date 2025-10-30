RSpec.describe Teachers::Defer do
  let(:author) { Events::LeadProviderAPIAuthor.new(lead_provider:) }
  let(:lead_provider) { training_period.lead_provider }
  let(:reason) { TrainingPeriod.deferral_reasons.values.map(&:dasherize).freeze.sample }
  let(:teacher) { training_period.trainee.teacher }

  let(:service) do
    described_class.new(
      author:,
      lead_provider:,
      reason:,
      teacher:,
      training_period:
    )
  end

  describe "#defer" do
    %i[ect mentor].each do |trainee_type|
      context "for #{trainee_type}" do
        let(:at_school_period) { FactoryBot.create(:"#{trainee_type}_at_school_period", started_on: 6.months.ago, finished_on: nil) }
        let(:course_identifier) { trainee_type == :ect ? "ecf-induction" : "ecf-mentor" }

        context "when training period is withdrawn" do
          let!(:training_period) { FactoryBot.create(:training_period, :"for_#{trainee_type}", :withdrawn, "#{trainee_type}_at_school_period": at_school_period, started_on: at_school_period.started_on) }

          it "raises an error if the training period is withdrawn" do
            expect {
              service.defer
            }.to raise_error(ActiveRecord::RecordInvalid, /A training period cannot be both withdrawn and deferred/)
          end
        end

        context "when training period is ongoing" do
          let!(:training_period) { FactoryBot.create(:training_period, :"for_#{trainee_type}", :ongoing, "#{trainee_type}_at_school_period": at_school_period, started_on: at_school_period.started_on) }

          it "defers the training period" do
            freeze_time

            expect(service.defer).not_to be(false)

            training_period.reload
            expect(training_period.deferred_at).to eq(Time.zone.now)
            expect(training_period.deferral_reason.dasherize).to eq(reason)
            expect(training_period.finished_on).to eq(training_period.deferred_at.to_date)
          end
        end

        context "when training period is already finished in the past" do
          let!(:training_period) do
            FactoryBot.create(
              :training_period,
              :"for_#{trainee_type}",
              :ongoing,
              "#{trainee_type}_at_school_period": at_school_period,
              started_on: at_school_period.started_on,
              finished_on: 1.month.ago
            )
          end

          it "sets `deferred_at` to the current date and doesn't change `finished_on`" do
            freeze_time

            expect(service.defer).not_to be(false)

            training_period.reload
            expect(training_period.deferred_at).to eq(Time.zone.now)
            expect(training_period.deferral_reason.dasherize).to eq(reason)
            expect(training_period.finished_on).to eq(1.month.ago.to_date)
          end
        end

        context "when training period will finished in the future" do
          let!(:training_period) do
            FactoryBot.create(
              :training_period,
              :"for_#{trainee_type}",
              :ongoing,
              "#{trainee_type}_at_school_period": at_school_period,
              started_on: at_school_period.started_on,
              finished_on: 3.months.from_now
            )
          end

          it "sets `deferred_at` and `finished_on` to the current date" do
            freeze_time

            expect(service.defer).not_to be(false)

            training_period.reload
            expect(training_period.deferred_at).to eq(Time.zone.now)
            expect(training_period.deferral_reason.dasherize).to eq(reason)
            expect(training_period.finished_on).to eq(training_period.deferred_at.to_date)
          end
        end

        context "event recording" do
          let!(:training_period) { FactoryBot.create(:training_period, :"for_#{trainee_type}", :ongoing, "#{trainee_type}_at_school_period": at_school_period, started_on: at_school_period.started_on) }

          it "records a teacher defers training period event" do
            freeze_time do
              expect(Events::Record).to receive(:record_teacher_training_period_deferred_event!)
                .with(author:,
                      teacher:,
                      lead_provider:,
                      training_period:,
                      modifications: {
                        finished_on: [nil, Time.zone.today],
                        updated_at: [training_period.updated_at, Time.zone.now],
                        deferral_reason: [nil, reason.underscore],
                        deferred_at: [nil, Time.zone.now]
                      })

              service.defer
            end
          end
        end
      end
    end
  end
end
