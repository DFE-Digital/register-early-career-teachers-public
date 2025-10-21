RSpec.describe API::Teachers::Defer, type: :model do
  let(:reason) { described_class::DEFERRAL_REASONS.sample }
  let(:instance) { described_class.new(lead_provider_id:, teacher_api_id:, course_identifier:, reason:) }

  it_behaves_like "an API teacher shared action" do
    describe "validations" do
      it { is_expected.to validate_inclusion_of(:reason).in_array(described_class::DEFERRAL_REASONS).with_message("The property '#/reason' must be a valid reason") }

      context "when the teacher training period is already deferred" do
        let!(:training_period) do
          FactoryBot.create(
            :training_period,
            :for_ect,
            :finished,
            :with_school_partnership,
            :deferred,
            school_partnership:,
            ect_at_school_period:,
            started_on: ect_at_school_period.started_on + 1.week
          )
        end

        it { expect(instance).to have_error(:teacher_api_id, "The '#/teacher_api_id' is already deferred.") }
      end

      context "when the teacher training period is withdrawn" do
        let!(:training_period) do
          FactoryBot.create(
            :training_period,
            :for_ect,
            :finished,
            :with_school_partnership,
            :withdrawn,
            school_partnership:,
            ect_at_school_period:,
            started_on: ect_at_school_period.started_on + 1.week
          )
        end

        it { expect(instance).to have_error(:teacher_api_id, "The '#/teacher_api_id' is already withdrawn.") }
      end
    end

    it "defers the training period successfully" do
      freeze_time do
        expect(instance.defer).to be true

        training_period = TrainingPeriod.find_by(ect_at_school_period:)

        expect(training_period.deferral_reason).to eq(reason.underscore)
        expect(training_period.deferred_at).to eq(Time.zone.now)
        expect(training_period.finished_on).to eq(Time.zone.today)
      end
    end

    context "when training period `finished_on` date is earlier than the deferral date" do
      before { training_period.update!(finished_on: 1.week.ago) }

      it "defers the training period successfully" do
        freeze_time do
          expect(instance.defer).to be true

          training_period = TrainingPeriod.find_by(ect_at_school_period:)

          expect(training_period.deferral_reason).to eq(reason.underscore)
          expect(training_period.deferred_at).to eq(Time.zone.now)
          expect(training_period.finished_on).to eq(1.week.ago.to_date)
        end
      end
    end

    context "when training period `finished_on` date is later than the deferral date" do
      before { training_period.update!(finished_on: 1.week.from_now) }

      it "defers the training period and updates the training period `finished_on`" do
        freeze_time do
          expect(instance.defer).to be true

          training_period = TrainingPeriod.find_by(ect_at_school_period:)

          expect(training_period.deferral_reason).to eq(reason.underscore)
          expect(training_period.deferred_at).to eq(Time.zone.now)
          expect(training_period.finished_on).to eq(Time.zone.today)
        end
      end
    end

    it "records a teacher training period deferred event" do
      freeze_time do
        expect(Events::Record).to receive(:record_teacher_defers_training_period_event!)
          .with(author: an_instance_of(Events::LeadProviderAPIAuthor),
                teacher:,
                lead_provider:,
                training_period:,
                modifications: {
                  deferral_reason: [nil, reason.underscore],
                  deferred_at: [nil, Time.zone.now],
                  finished_on: [nil, Time.zone.today],
                  updated_at: [training_period.updated_at, Time.zone.now]
                })

        instance.defer
      end
    end
  end
end
