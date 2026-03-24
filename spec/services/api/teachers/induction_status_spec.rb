RSpec.describe API::Teachers::InductionStatus, type: :model do
  let(:instance) { described_class.new(teacher:) }

  describe "#induction_end_date" do
    subject { instance.induction_end_date }

    context "when the teacher has a TRS induction completed date" do
      let(:teacher) { FactoryBot.create(:teacher, trs_induction_completed_date: 1.month.ago) }

      it { is_expected.to eq(teacher.trs_induction_completed_date) }
    end

    context "when the teacher has a finished induction period" do
      let(:teacher) { finished_induction_period.teacher }
      let(:finished_induction_period) { FactoryBot.create(:induction_period, :pass) }

      it { is_expected.to eq(finished_induction_period.finished_on) }
    end

    context "when the teacher has both a TRS induction completed date and a finished induction period" do
      let(:teacher) { finished_induction_period.teacher }
      let(:finished_induction_period) { FactoryBot.create(:induction_period, :pass) }

      before { teacher.update!(trs_induction_completed_date: 1.month.ago) }

      it { is_expected.to eq(finished_induction_period.finished_on) }
    end

    context "when the teacher does not have a TRS induction completed date or a finished induction period" do
      let(:teacher) { FactoryBot.create(:teacher) }

      it { is_expected.to be_nil }
    end
  end

  describe "#induction_start_date" do
    subject { instance.induction_start_date }

    context "when the teacher has a TRS induction start date" do
      let(:teacher) { FactoryBot.create(:teacher, trs_induction_start_date: 1.month.ago) }

      it { is_expected.to eq(teacher.trs_induction_start_date) }
    end

    context "when the teacher has a started induction period" do
      let(:teacher) { started_induction_period.teacher }
      let(:started_induction_period) { FactoryBot.create(:induction_period, :pass) }

      it { is_expected.to eq(started_induction_period.started_on) }
    end

    context "when the teacher has both a TRS induction start date and a started induction period" do
      let(:teacher) { started_induction_period.teacher }
      let(:started_induction_period) { FactoryBot.create(:induction_period, :pass) }

      before { teacher.update!(trs_induction_start_date: 1.month.ago) }

      it { is_expected.to eq(started_induction_period.started_on) }
    end

    context "when the teacher does not have a TRS induction start date or a started induction period" do
      let(:teacher) { FactoryBot.create(:teacher) }

      it { is_expected.to be_nil }
    end
  end

  describe "#completed_induction?" do
    subject { instance }

    context "when the teacher has a TRS induction completed date" do
      let(:teacher) { FactoryBot.create(:teacher, trs_induction_completed_date: 1.month.ago) }

      it { is_expected.to be_completed_induction }
    end

    context "when the teacher has a finished induction period" do
      let(:teacher) { FactoryBot.create(:induction_period, :pass).teacher }

      it { is_expected.to be_completed_induction }
    end

    context "when the teacher does not have a TRS induction completed date or a finished induction period" do
      let(:teacher) { FactoryBot.create(:teacher) }

      it { is_expected.not_to be_completed_induction }
    end
  end
end
