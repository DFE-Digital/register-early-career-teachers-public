RSpec.describe API::Teachers::Withdraw, :with_metadata, type: :model do
  subject do
    described_class.new(
      lead_provider_id:,
      teacher_api_id:,
      reason:,
      course_identifier:
    )
  end

  let(:lead_provider_id) { training_period.lead_provider.id }
  let(:teacher_api_id) { training_period.trainee.teacher.api_id }
  let(:reason) { TrainingPeriod.withdrawal_reasons.values.sample.dasherize }

  describe "validations" do
    %i[ect mentor].each do |trainee_type|
      context "for #{trainee_type}" do
        let(:at_school_period) { FactoryBot.create(:"#{trainee_type}_at_school_period", started_on: 2.months.ago) }
        let!(:training_period) { FactoryBot.create(:training_period, :"for_#{trainee_type}", :ongoing, "#{trainee_type}_at_school_period": at_school_period, started_on: at_school_period.started_on) }
        let(:course_identifier) { trainee_type == :ect ? "ecf-induction" : "ecf-mentor" }

        it { is_expected.to be_valid }

        it { is_expected.to validate_presence_of(:lead_provider_id).with_message("Enter a '#/lead_provider_id'.") }
        it { is_expected.to validate_presence_of(:teacher_api_id).with_message("Enter a '#/teacher_api_id'.") }
        it { is_expected.to validate_presence_of(:reason).with_message("Enter a '#/reason'.") }
        it { is_expected.to validate_presence_of(:course_identifier).with_message("Enter a '#/course_identifier'.") }

        context "when the lead_provider does not exist" do
          let(:lead_provider_id) { 9999 }

          it "is invalid" do
            expect(subject).to be_invalid
            expect(subject.errors[:lead_provider_id]).to eq(["The '#/lead_provider_id' you have entered is invalid."])
          end
        end

        context "when the teacher does not exist" do
          let(:teacher_api_id) { SecureRandom.uuid }

          it "is invalid" do
            expect(subject).to be_invalid
            expect(subject.errors[:teacher_api_id]).to eq(["Your update cannot be made as the '#/teacher_api_id' is not recognised. Check participant details and try again."])
          end
        end

        context "when teacher exists but training_period does not exist" do
          let(:teacher_api_id) { FactoryBot.create(:teacher).api_id }

          it "is invalid" do
            expect(subject).to be_invalid
            expect(subject.errors[:teacher_api_id]).to eq(["Your update cannot be made as the '#/teacher_api_id' is not recognised. Check participant details and try again."])
          end
        end

        context "when course_identifier is invalid" do
          let(:course_identifier) { "does-not-exist" }

          it "is invalid" do
            expect(subject).to be_invalid
            expect(subject.errors[:course_identifier]).to eq(["The entered '#/course_identifier' is not recognised for the given participant. Check details and try again."])
          end
        end

        context "when reason is invalid" do
          let(:reason) { "does-not-exist" }

          it "is invalid" do
            expect(subject).to be_invalid
            expect(subject.errors[:reason]).to eq(["The entered '#/reason' is not recognised for the given participant. Check details and try again."])
          end
        end

        context "when reason values are dashed" do
          TrainingPeriod.withdrawal_reasons.values.map(&:dasherize).each do |reason_val|
            let(:reason) { reason_val }

            it "is valid when reason is '#{reason_val}'" do
              expect(subject).to be_valid
            end
          end
        end

        context "when reason is underscored" do
          let(:reason) { "left_teaching_profession" }

          it "is invalid when reason is 'left_teaching_profession'" do
            expect(subject).to be_invalid
            expect(subject.errors[:reason]).to eq(["The entered '#/reason' is not recognised for the given participant. Check details and try again."])
          end
        end

        context "when teacher already withdrawn" do
          let!(:training_period) { FactoryBot.create(:training_period, :"for_#{trainee_type}", :withdrawn, "#{trainee_type}_at_school_period": at_school_period, started_on: at_school_period.started_on) }

          it "is invalid" do
            expect(subject).to be_invalid
            expect(subject.errors[:teacher_api_id]).to eq(["The '#/teacher_api_id' is already withdrawn."])
          end
        end

        context "guarded error messages" do
          subject { described_class.new }

          it { is_expected.to have_one_error_per_attribute }
        end
      end
    end
  end

  describe "#withdraw" do
    %i[ect mentor].each do |trainee_type|
      context "for #{trainee_type}" do
        let(:at_school_period) { FactoryBot.create(:"#{trainee_type}_at_school_period", started_on: 6.months.ago, finished_on: nil) }
        let(:course_identifier) { trainee_type == :ect ? "ecf-induction" : "ecf-mentor" }

        before do
          allow(Events::Record).to receive(:record_teacher_withdraws_training_period_event!).once
        end

        context "when invalid" do
          let!(:training_period) { FactoryBot.create(:training_period, :"for_#{trainee_type}", :ongoing) }
          let(:teacher_api_id) { SecureRandom.uuid }

          it { expect(subject.withdraw).to be(false) }
          it { expect { subject.withdraw }.not_to(change { training_period.reload.attributes }) }
        end

        context "when training period ongoing" do
          let!(:training_period) { FactoryBot.create(:training_period, :"for_#{trainee_type}", :ongoing, "#{trainee_type}_at_school_period": at_school_period, started_on: at_school_period.started_on) }

          it "withdraws training period" do
            freeze_time

            expect(subject.withdraw).not_to be(false)

            training_period.reload
            expect(training_period.withdrawn_at).to eq(Time.zone.now)
            expect(training_period.withdrawal_reason.dasherize).to eq(reason)
            expect(training_period.finished_on).to eq(Time.zone.now.to_date)

            expect(Events::Record).to have_received(:record_teacher_withdraws_training_period_event!)
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

          it "sets withdrawn_at to the finished_on date as it is in the past" do
            freeze_time

            expect(subject.withdraw).not_to be(false)

            training_period.reload
            expect(training_period.withdrawn_at).to eq(Time.zone.now)
            expect(training_period.withdrawal_reason.dasherize).to eq(reason)
            expect(training_period.finished_on).to eq(1.month.ago.to_date)

            expect(Events::Record).to have_received(:record_teacher_withdraws_training_period_event!)
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

          it "sets withdrawn_at to Time.zone.now as it is before finished_on" do
            freeze_time

            expect(subject.withdraw).not_to be(false)

            training_period.reload
            expect(training_period.withdrawn_at).to eq(Time.zone.now)
            expect(training_period.withdrawal_reason.dasherize).to eq(reason)
            expect(training_period.finished_on).to eq(Time.zone.today)

            expect(Events::Record).to have_received(:record_teacher_withdraws_training_period_event!)
          end
        end
      end
    end
  end
end
