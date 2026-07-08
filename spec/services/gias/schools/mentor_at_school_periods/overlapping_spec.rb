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

  describe "#call" do
    context "when periods are adjacent" do
      let(:first_period_started_on) { Date.new(2025, 1, 1) }
      let(:first_period_finished_on) { Date.new(2025, 3, 31) }
      let(:second_period_started_on) { Date.new(2025, 4, 1) }
      let(:second_period_finished_on) { Date.new(2025, 6, 30) }

      it "returns them as one merge group" do
        expect(groups).to eq([[first_period, second_period]])
      end
    end

    context "when periods have a gap" do
      let(:first_period_started_on) { Date.new(2025, 1, 1) }
      let(:first_period_finished_on) { Date.new(2025, 3, 31) }
      let(:second_period_started_on) { Date.new(2025, 4, 2) }
      let(:second_period_finished_on) { Date.new(2025, 6, 30) }

      it "does not return either period" do
        expect(groups).to be_empty
      end
    end

    context "when periods overlap transitively" do
      let(:first_period_started_on) { Date.new(2025, 1, 1) }
      let(:first_period_finished_on) { Date.new(2025, 3, 31) }
      let(:second_period_started_on) { Date.new(2025, 3, 1) }
      let(:second_period_finished_on) { Date.new(2025, 11, 30) }

      let!(:third_period) do
        FactoryBot.create(
          :mentor_at_school_period,
          teacher:,
          school: first_school,
          started_on: Date.new(2025, 11, 1),
          finished_on: Date.new(2025, 12, 31)
        )
      end

      it "returns all periods as one merge group" do
        expect(groups).to eq([
          [first_period, second_period, third_period]
        ])
      end
    end

    context "when two periods overlap but a third period is separate" do
      let(:first_period_started_on) { Date.new(2025, 1, 1) }
      let(:first_period_finished_on) { Date.new(2025, 3, 31) }
      let(:second_period_started_on) { Date.new(2025, 3, 1) }
      let(:second_period_finished_on) { Date.new(2025, 11, 30) }

      let!(:third_period) do
        FactoryBot.create(
          :mentor_at_school_period,
          teacher:,
          school: first_school,
          started_on: Date.new(2025, 12, 15),
          finished_on: Date.new(2025, 12, 31)
        )
      end

      it "returns all periods as one merge group" do
        expect(groups).to eq([
          [first_period, second_period]
        ])
      end
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

    context "when the resulting group is ongoing" do
      let(:first_period_started_on) { Date.new(2025, 1, 1) }
      let(:first_period_finished_on) { Date.new(2025, 3, 31) }
      let(:second_period_started_on) { Date.new(2025, 4, 1) }
      let(:second_period_finished_on) { nil }

      it "returns the periods as one merge group" do
        expect(groups).to eq([[first_period, second_period]])
      end
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

      it "only groups periods for the requested teacher and schools" do
        groups.each do |group|
          expect(group).not_to include(other_school_period)
        end
      end
    end

    context "when the teacher only has periods at one school" do
      let(:first_period_started_on) { Date.new(2025, 1, 1) }
      let(:first_period_finished_on) { Date.new(2025, 3, 31) }
      let(:second_period_started_on) { Date.new(2025, 5, 1) }
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

      it "returns an empty array" do
        expect(groups).to be_empty
      end
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
          finished_on: Date.new(2025, 12, 31)
        )
      end

      let!(:another_teacher_period) do
        FactoryBot.create(
          :mentor_at_school_period,
          teacher: another_teacher,
          school: second_school,
          started_on: Date.new(2025, 1, 1),
          finished_on: Date.new(2025, 12, 31)
        )
      end

      it "only groups periods for the requested teacher and schools" do
        groups.each do |group|
          expect(group).not_to include(other_teacher_period)
          expect(group).not_to include(another_teacher_period)
        end
      end
    end
  end
end
