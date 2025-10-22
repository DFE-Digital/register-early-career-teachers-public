RSpec.describe API::Teachers::Defer, type: :model do
  subject(:instance) do
    described_class.new(
      lead_provider_id:,
      teacher_api_id:,
      reason:,
      course_identifier:
    )
  end

  let(:reason) { described_class::DEFERRAL_REASONS.sample }

  it_behaves_like "an API teacher shared action" do
    describe "validations" do
      %i[ect mentor].each do |trainee_type|
        context "for #{trainee_type}" do
          let(:at_school_period) { FactoryBot.create(:"#{trainee_type}_at_school_period", started_on: 2.months.ago) }
          let!(:training_period) { FactoryBot.create(:training_period, :"for_#{trainee_type}", :ongoing, "#{trainee_type}_at_school_period": at_school_period, started_on: at_school_period.started_on) }
          let(:course_identifier) { trainee_type == :ect ? "ecf-induction" : "ecf-mentor" }

          context "when reason is invalid" do
            let(:reason) { "does-not-exist" }

            it { is_expected.to have_one_error_per_attribute }
            it { is_expected.to have_error(:reason, "The entered '#/reason' is not recognised for the given participant. Check details and try again.") }
          end

          context "when reason values are dashed" do
            described_class::DEFERRAL_REASONS.each do |reason_val|
              let(:reason) { reason_val }

              it "is valid when reason is '#{reason_val}'" do
                expect(instance).to be_valid
              end
            end
          end

          context "when reason is underscored" do
            let(:reason) { "long_term_sickness" }

            it { is_expected.to have_one_error_per_attribute }
            it { is_expected.to have_error(:reason, "The entered '#/reason' is not recognised for the given participant. Check details and try again.") }
          end

          context "when teacher already withdrawn" do
            let!(:training_period) { FactoryBot.create(:training_period, :"for_#{trainee_type}", :withdrawn, "#{trainee_type}_at_school_period": at_school_period, started_on: at_school_period.started_on) }

            it { is_expected.to have_one_error_per_attribute }
            it { is_expected.to have_error(:teacher_api_id, "The '#/teacher_api_id' is already withdrawn.") }
          end

          context "when teacher already deferred" do
            let!(:training_period) { FactoryBot.create(:training_period, :"for_#{trainee_type}", :deferred, "#{trainee_type}_at_school_period": at_school_period, started_on: at_school_period.started_on) }

            it { is_expected.to have_one_error_per_attribute }
            it { is_expected.to have_error(:teacher_api_id, "The '#/teacher_api_id' is already deferred.") }
          end

          context "guarded error messages" do
            subject(:instance) { described_class.new }

            it { is_expected.to have_one_error_per_attribute }
          end
        end
      end
    end

    describe "#defer" do
      %i[ect mentor].each do |trainee_type|
        context "for #{trainee_type}" do
          let(:at_school_period) { FactoryBot.create(:"#{trainee_type}_at_school_period", started_on: 6.months.ago, finished_on: nil) }
          let(:course_identifier) { trainee_type == :ect ? "ecf-induction" : "ecf-mentor" }

          context "when invalid" do
            let!(:training_period) { FactoryBot.create(:training_period, :"for_#{trainee_type}", :ongoing) }
            let(:teacher_api_id) { SecureRandom.uuid }

            it { expect(instance.defer).to be(false) }
            it { expect { instance.defer }.not_to(change { training_period.reload.attributes }) }
          end

          context "when training period ongoing" do
            let!(:training_period) { FactoryBot.create(:training_period, :"for_#{trainee_type}", :ongoing, "#{trainee_type}_at_school_period": at_school_period, started_on: at_school_period.started_on) }

            it "withdraws training period" do
              freeze_time

              expect(instance.defer).not_to be(false)

              training_period.reload
              expect(training_period.deferred_at).to eq(Time.zone.now)
              expect(training_period.deferral_reason.dasherize).to eq(reason)
              expect(training_period.finished_on).to eq(training_period.deferred_at.to_date)
            end
          end

          context "when training period already finished in the past" do
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

            it "sets `deferred_at` to the current date and doesn't change finished_on" do
              freeze_time

              expect(instance.defer).not_to be(false)

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

            it "sets `deferred_at` and finished_on to the current date" do
              freeze_time

              expect(instance.defer).not_to be(false)

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
                expect(Events::Record).to receive(:record_teacher_defers_training_period_event!)
                  .with(author: an_instance_of(Events::LeadProviderAPIAuthor),
                        teacher:,
                        lead_provider:,
                        training_period:,
                        modifications: {
                          finished_on: [nil, Time.zone.today],
                          updated_at: [training_period.updated_at, Time.zone.now],
                          deferral_reason: [nil, reason.underscore],
                          deferred_at: [nil, Time.zone.now]
                        })

                instance.defer
              end
            end
          end
        end
      end
    end
  end
end
