RSpec.describe GIAS::Reconciliation::MentorAtSchoolPeriods::Overlapping do
  subject { described_class.find(teacher:, schools:) }

  let(:teacher) { FactoryBot.create(:teacher) }
  let(:first_school) { FactoryBot.create(:school) }
  let(:second_school) { FactoryBot.create(:school) }

  let(:schools) { [first_school, second_school] }
  let!(:periods) { [first_period, second_period] }

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

  let(:third_period) do
    FactoryBot.create(
      :mentor_at_school_period,
      teacher:,
      school: first_school,
      started_on: third_period_started_on,
      finished_on: third_period_finished_on
    )
  end

  let(:fourth_period) do
    FactoryBot.create(
      :mentor_at_school_period,
      teacher:,
      school: second_school,
      started_on: fourth_period_started_on,
      finished_on: fourth_period_finished_on
    )
  end

  let(:first_period_started_on) { Date.new(2025, 1, 1) }
  let(:first_period_finished_on) { Date.new(2025, 3, 31) }
  let(:second_period_started_on) { Date.new(2025, 4, 1) }
  let(:second_period_finished_on) { Date.new(2025, 6, 30) }

  describe "#find" do
    it_behaves_like "it identifies overlapping periods"

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
        expect(subject).to be_empty
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

    context "when there are mentor periods belonging to other teachers at the schools" do
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
        expect(subject).to be_empty
      end
    end
  end
end
