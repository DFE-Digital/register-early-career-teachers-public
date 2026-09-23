RSpec.describe Teachers::Withdraw do
  let(:author) { Events::LeadProviderAPIAuthor.new(lead_provider:) }
  let(:lead_provider) { training_period.lead_provider }
  let(:reason) { (TrainingPeriod.withdrawal_reasons.values - TrainingPeriod::MENTOR_ONLY_WITHDRAWAL_REASONS).map(&:dasherize).sample }
  let(:teacher) { training_period.teacher }

  let(:service) do
    described_class.new(
      author:,
      lead_provider:,
      reason:,
      teacher:,
      training_period:
    )
  end

  describe "#withdraw" do
    %i[ect mentor].each do |trainee_type|
      context "for #{trainee_type}" do
        let(:at_school_period) { FactoryBot.create(:"#{trainee_type}_at_school_period", started_on: 6.months.ago, finished_on: nil) }
        let(:teacher_type) { trainee_type }

        context "when training period is ongoing" do
          let!(:training_period) { FactoryBot.create(:training_period, :"for_#{trainee_type}", :unfinished, "#{trainee_type}_at_school_period": at_school_period, started_on: at_school_period.started_on) }

          it "withdraws training period" do
            freeze_time

            expect(service.withdraw).not_to be(false)

            training_period.reload
            expect(training_period.withdrawn_at).to eq(Time.zone.now)
            expect(training_period.withdrawal_reason.dasherize).to eq(reason)
            expect(training_period.finished_on).to eq(training_period.withdrawn_at.to_date)
          end
        end

        context "when training period is already finished in the past" do
          let!(:training_period) do
            FactoryBot.create(
              :training_period,
              :"for_#{trainee_type}",
              :unfinished,
              "#{trainee_type}_at_school_period": at_school_period,
              started_on: at_school_period.started_on,
              finished_on: 1.month.ago
            )
          end

          it "sets `withdrawn_at` to the current date and doesn't change `finished_on`" do
            freeze_time

            expect(service.withdraw).not_to be(false)

            training_period.reload
            expect(training_period.withdrawn_at).to eq(Time.zone.now)
            expect(training_period.withdrawal_reason.dasherize).to eq(reason)
            expect(training_period.finished_on).to eq(1.month.ago.to_date)
          end
        end

        context "when training period will finished in the future" do
          let!(:training_period) do
            FactoryBot.create(
              :training_period,
              :"for_#{trainee_type}",
              :unfinished,
              "#{trainee_type}_at_school_period": at_school_period,
              started_on: at_school_period.started_on,
              finished_on: 3.months.from_now
            )
          end

          it "sets `withdrawn_at` and `finished_on` to the current date" do
            freeze_time

            expect(service.withdraw).not_to be(false)

            training_period.reload
            expect(training_period.withdrawn_at).to eq(Time.zone.now)
            expect(training_period.withdrawal_reason.dasherize).to eq(reason)
            expect(training_period.finished_on).to eq(training_period.withdrawn_at.to_date)
          end
        end

        context "event recording" do
          let!(:training_period) { FactoryBot.create(:training_period, :"for_#{trainee_type}", :unfinished, "#{trainee_type}_at_school_period": at_school_period, started_on: at_school_period.started_on) }

          it "records a teacher withdraws training period event" do
            freeze_time do
              previous_updated_at = training_period.updated_at

              service.withdraw

              event = Event.where(event_type: "teacher_withdraws_training_period").sole
              expect(event).to have_attributes(
                teacher_id: teacher.id,
                lead_provider_id: lead_provider.id,
                training_period_id: training_period.id
              )
              expect(event.metadata).to eq(
                "finished_on" => [nil, Time.zone.today.as_json],
                "updated_at" => [previous_updated_at.as_json, Time.zone.now.as_json],
                "withdrawal_reason" => [nil, reason.underscore],
                "withdrawn_at" => [nil, Time.zone.now.as_json]
              )
            end
          end
        end
      end
    end
  end
end
