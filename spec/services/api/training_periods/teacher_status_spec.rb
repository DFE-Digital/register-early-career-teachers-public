RSpec.describe API::TrainingPeriods::TeacherStatus do
  let(:service) { described_class.new(latest_training_period: training_period, teacher:) }
  let(:teacher) { training_period.teacher }

  describe "#status" do
    subject { service.status }

    context "when training period set to start in the future" do
      let(:training_period) { FactoryBot.create(:training_period, :not_started_yet) }

      it { is_expected.to eq(:joining) }
    end

    context "when training period has started and not finished" do
      let(:training_period) { FactoryBot.create(:training_period, :ongoing) }

      it { is_expected.to eq(:active) }
    end

    context "when training period is to finish in the future" do
      let(:started_on) { 3.months.ago }
      let(:finished_on) { 1.month.from_now }
      let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, started_on:, finished_on:) }
      let(:training_period) { FactoryBot.create(:training_period, ect_at_school_period:, started_on:, finished_on:) }

      it { is_expected.to eq(:leaving) }

      context "when training period set to both start and finish in the future" do
        let(:training_period) { FactoryBot.create(:training_period, ect_at_school_period:, started_on: 1.week.from_now, finished_on:) }

        it { is_expected.to eq(:leaving) }
      end
    end

    context "when training period has already finished" do
      context "when the teacher is acting as an ECT for this training period" do
        let(:training_period) { FactoryBot.create(:training_period, :for_ect, :finished) }

        it { is_expected.to eq(:left) }

        context "when completed induction (pass or fail are treated the same)" do
          before do
            # complete induction
            FactoryBot.create(:induction_period, :pass, teacher:)
          end

          it { is_expected.to eq(:active) }
        end

        context "when completed induction after training period" do
          before do
            # complete induction
            FactoryBot.create(
              :induction_period, :pass, teacher:,
                                        started_on: training_period.started_on,
                                        finished_on: training_period.finished_on + 1.week
            )
          end

          it { is_expected.to eq(:active) }
        end
      end

      context "when the teacher is acting as a mentor for this training period" do
        let(:training_period) { FactoryBot.create(:training_period, :for_mentor, :finished) }

        it { is_expected.to eq(:left) }

        context "when teacher becomes ineligible before period has finished" do
          before do
            teacher.update!(
              mentor_became_ineligible_for_funding_on: training_period.finished_on - 1.week,
              mentor_became_ineligible_for_funding_reason: "completed_declaration_received"
            )
          end

          it { is_expected.to eq(:active) }
        end

        context "when teacher becomes ineligible when period has finished" do
          before do
            teacher.update!(
              mentor_became_ineligible_for_funding_on: training_period.finished_on,
              mentor_became_ineligible_for_funding_reason: "completed_declaration_received"
            )
          end

          it { is_expected.to eq(:active) }
        end

        context "when teacher becomes ineligible after period has finished" do
          before do
            teacher.update!(
              mentor_became_ineligible_for_funding_on: training_period.finished_on + 1.day,
              mentor_became_ineligible_for_funding_reason: "completed_declaration_received"
            )
          end

          it { is_expected.to eq(:left) }
        end
      end
    end
  end
end
