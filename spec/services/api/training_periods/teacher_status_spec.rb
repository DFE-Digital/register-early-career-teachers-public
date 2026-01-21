RSpec.describe API::TrainingPeriods::TeacherStatus do
  let(:service) { described_class.new(latest_training_period: training_period, teacher:) }
  let(:teacher) { training_period.teacher }

  describe "#status" do
    subject { service.status }

    context "when training period has started and not set to finish" do
      let(:training_period) { FactoryBot.build(:training_period, :ongoing) }

      it { is_expected.to eq(:active) }
      it { expect(service).to be_active }
      it { expect(service).not_to be_joining }
      it { expect(service).not_to be_leaving }
      it { expect(service).not_to be_left }
    end

    context "when 'teacher.mentor_became_ineligible_for_funding_on' is set (indicating the mentor has completed training)" do
      let(:training_period) { FactoryBot.create(:training_period, :ongoing) }

      before do
        teacher.update!(
          mentor_became_ineligible_for_funding_on: 3.months.ago,
          mentor_became_ineligible_for_funding_reason: "completed_declaration_received"
        )
      end

      it { is_expected.to eq(:active) }
      it { expect(service).to be_active }
      it { expect(service).not_to be_joining }
      it { expect(service).not_to be_leaving }
      it { expect(service).not_to be_left }
    end

    context "when 'finished_induction_period.finished_on' is set (indicating the ECT has completed training)" do
      let(:training_period) { FactoryBot.create(:training_period, :ongoing) }

      before do
        FactoryBot.create(:induction_period, :pass, teacher:)
      end

      it { is_expected.to eq(:active) }
      it { expect(service).to be_active }
      it { expect(service).not_to be_joining }
      it { expect(service).not_to be_leaving }
      it { expect(service).not_to be_left }
    end

    context "when training period set to start in the future" do
      let(:training_period) { FactoryBot.build(:training_period, :not_started_yet) }

      it { is_expected.to eq(:joining) }
      it { expect(service).not_to be_active }
      it { expect(service).to be_joining }
      it { expect(service).not_to be_leaving }
      it { expect(service).not_to be_left }
    end

    context "when training period set to finish in the future" do
      let(:training_period) { FactoryBot.build(:training_period, started_on: 3.months.ago, finished_on: 5.months.from_now) }

      it { is_expected.to eq(:leaving) }
      it { expect(service).not_to be_active }
      it { expect(service).not_to be_joining }
      it { expect(service).to be_leaving }
      it { expect(service).not_to be_left }
    end

    context "when training period has already finished" do
      let(:training_period) { FactoryBot.build(:training_period, started_on: 12.months.ago, finished_on: 2.months.ago) }

      it { is_expected.to eq(:left) }
      it { expect(service).not_to be_active }
      it { expect(service).not_to be_joining }
      it { expect(service).not_to be_leaving }
      it { expect(service).to be_left }
    end
  end
end
