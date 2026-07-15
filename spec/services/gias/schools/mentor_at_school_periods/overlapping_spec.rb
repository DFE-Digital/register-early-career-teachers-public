RSpec.describe GIAS::Schools::MentorAtSchoolPeriods::Overlapping do
  subject(:groups) { described_class.find(teacher:, schools:) }

  let(:teacher) { FactoryBot.create(:teacher) }
  let(:first_school) { FactoryBot.create(:school) }
  let(:second_school) { FactoryBot.create(:school) }

  let(:schools) { [first_school, second_school] }

  let!(:first_period) do
    FactoryBot.create(
      :mentor_at_school_period,
      teacher:,
      school: first_school,
      started_on: first_period_started_on,
      finished_on: first_period_finished_on
    )
  end

  let!(:second_period) do
    FactoryBot.create(
      :mentor_at_school_period,
      teacher:,
      school: second_school,
      started_on: second_period_started_on,
      finished_on: second_period_finished_on
    )
  end

  describe "#find" do
    context "when two periods overlap" do
      let(:first_period_started_on) { Date.new(2025, 1, 1) }
      let(:first_period_finished_on) { Date.new(2025, 3, 31) }
      let(:second_period_started_on) { Date.new(2025, 3, 1) }
      let(:second_period_finished_on) { Date.new(2025, 6, 30) }

      it { is_expected.to eq([[first_period, second_period]]) }
    end

    context "when periods are adjacent" do
      let(:first_period_started_on) { Date.new(2025, 1, 1) }
      let(:first_period_finished_on) { Date.new(2025, 3, 31) }
      let(:second_period_started_on) { Date.new(2025, 4, 1) }
      let(:second_period_finished_on) { Date.new(2025, 6, 30) }

      it { is_expected.to be_empty }
    end

    context "when periods have a gap" do
      let(:first_period_started_on) { Date.new(2025, 1, 1) }
      let(:first_period_finished_on) { Date.new(2025, 3, 31) }
      let(:second_period_started_on) { Date.new(2025, 4, 2) }
      let(:second_period_finished_on) { Date.new(2025, 6, 30) }

      it { is_expected.to be_empty }
    end

    context "when periods overlap transitively" do
      let(:first_period_started_on) { Date.new(2025, 1, 1) }
      let(:first_period_finished_on) { Date.new(2025, 3, 31) }
      let(:second_period_started_on) { Date.new(2025, 3, 1) }
      let(:second_period_finished_on) { Date.new(2025, 11, 30) }

      let!(:third_period) { FactoryBot.create(:mentor_at_school_period, teacher:, school: first_school, started_on: Date.new(2025, 11, 1), finished_on: Date.new(2025, 12, 31)) }

      it { is_expected.to eq([[first_period, second_period, third_period]]) }
    end

    context "when two periods overlap but a third period is separate" do
      let(:first_period_started_on) { Date.new(2025, 1, 1) }
      let(:first_period_finished_on) { Date.new(2025, 3, 31) }
      let(:second_period_started_on) { Date.new(2025, 3, 1) }
      let(:second_period_finished_on) { Date.new(2025, 11, 30) }

      let!(:third_period) { FactoryBot.create(:mentor_at_school_period, teacher:, school: first_school, started_on: Date.new(2025, 12, 15), finished_on: Date.new(2025, 12, 31)) }

      it { is_expected.to eq([[first_period, second_period]]) }
    end

    context "when there are two separate groups of overlapping periods" do
      let(:first_period_started_on) { Date.new(2025, 1, 1) }
      let(:first_period_finished_on) { Date.new(2025, 3, 31) }
      let(:second_period_started_on) { Date.new(2025, 3, 15) }
      let(:second_period_finished_on) { Date.new(2025, 6, 30) }

      let!(:third_period) do
        FactoryBot.create(
          :mentor_at_school_period,
          teacher:,
          school: first_school,
          started_on: Date.new(2025, 7, 15),
          finished_on: Date.new(2025, 9, 30)
        )
      end

      let!(:fourth_period) do
        FactoryBot.create(
          :mentor_at_school_period,
          teacher:,
          school: second_school,
          started_on: Date.new(2025, 9, 1),
          finished_on: Date.new(2025, 12, 31)
        )
      end

      it "returns two separate merge groups" do
        expect(groups).to eq([
          [first_period, second_period],
          [third_period, fourth_period]
        ])
      end
    end

    context "when the earliest periods is ongoing" do
      let(:first_period_started_on) { Date.new(2025, 1, 1) }
      let(:first_period_finished_on) { nil }
      let(:second_period_started_on) { Date.new(2025, 4, 1) }
      let(:second_period_finished_on) { Date.new(2025, 6, 30) }

      it { is_expected.to eq([[first_period, second_period]]) }
    end

    context "when the teacher has periods at other schools" do
      let(:other_school) { FactoryBot.create(:school) }

      let(:first_period_started_on) { Date.new(2025, 1, 1) }
      let(:first_period_finished_on) { Date.new(2025, 3, 31) }
      let(:second_period_started_on) { Date.new(2025, 4, 1) }
      let(:second_period_finished_on) { Date.new(2025, 6, 30) }

      let!(:other_school_period) do
        FactoryBot.create(
          :mentor_at_school_period,
          teacher:,
          school: other_school,
          started_on: Date.new(2025, 1, 1),
          finished_on: Date.new(2025, 12, 31)
        )
      end

      it "does not include the other school period in the calculation" do
        expect(groups).to be_empty
      end
    end

    context "when the teacher only has periods at one school" do
      let(:first_period_started_on) { Date.new(2025, 1, 1) }
      let(:first_period_finished_on) { Date.new(2025, 3, 31) }
      let(:second_period_started_on) { Date.new(2025, 4, 1) }
      let(:second_period_finished_on) { Date.new(2025, 6, 30) }

      let!(:second_period) do
        FactoryBot.create(
          :mentor_at_school_period,
          teacher:,
          school: first_school,
          started_on: second_period_started_on,
          finished_on: second_period_finished_on
        )
      end

      it { is_expected.to be_empty }
    end

    context "when one school is given" do
      let(:schools) { [first_school] }

      let(:first_period_started_on) { Date.new(2025, 1, 1) }
      let(:first_period_finished_on) { Date.new(2025, 3, 31) }
      let(:second_period_started_on) { Date.new(2025, 4, 1) }
      let(:second_period_finished_on) { Date.new(2025, 6, 30) }

      it { is_expected.to be_empty }
    end

    context "when no schools are given" do
      let(:schools) { [] }

      let(:first_period_started_on) { Date.new(2025, 1, 1) }
      let(:first_period_finished_on) { Date.new(2025, 3, 31) }
      let(:second_period_started_on) { Date.new(2025, 4, 1) }
      let(:second_period_finished_on) { Date.new(2025, 6, 30) }

      it { is_expected.to be_empty }
    end

    context "when schools is nil" do
      let(:schools) { nil }

      let(:first_period_started_on) { Date.new(2025, 1, 1) }
      let(:first_period_finished_on) { Date.new(2025, 3, 31) }
      let(:second_period_started_on) { Date.new(2025, 4, 1) }
      let(:second_period_finished_on) { Date.new(2025, 6, 30) }

      it { is_expected.to be_empty }
    end

    context "when there mentor periods belonging to other teachers at the schools" do
      let(:other_teacher) { FactoryBot.create(:teacher) }
      let(:another_teacher) { FactoryBot.create(:teacher) }

      let(:first_period_started_on) { Date.new(2025, 1, 1) }
      let(:first_period_finished_on) { Date.new(2025, 3, 31) }
      let(:second_period_started_on) { Date.new(2025, 4, 1) }
      let(:second_period_finished_on) { Date.new(2025, 6, 30) }

      let!(:other_teacher_period) do
        FactoryBot.create(
          :mentor_at_school_period,
          teacher: other_teacher,
          school: first_school,
          started_on: Date.new(2025, 1, 1),
          finished_on: Date.new(2025, 5, 31)
        )
      end

      it "does not include the other teachers' periods in the calculation" do
        expect(groups).to be_empty
      end
    end
  end
end
