RSpec.describe Teachers::Overlapping do
  subject(:any_overlapping_periods?) do
    described_class
      .new(teacher:, other_teacher:)
      .any_overlapping_periods?
  end

  let(:teacher) { FactoryBot.create(:teacher) }
  let(:other_teacher) { FactoryBot.create(:teacher) }
  let(:school) { FactoryBot.create(:school) }
  let(:period_type) { :mentor_at_school_period }

  let!(:first_period) do
    FactoryBot.create(
      period_type,
      teacher:,
      school:,
      started_on: first_period_started_on,
      finished_on: first_period_finished_on
    )
  end

  let!(:second_period) do
    FactoryBot.create(
      period_type,
      teacher: other_teacher,
      started_on: second_period_started_on,
      finished_on: second_period_finished_on
    )
  end

  shared_examples "when two periods overlap" do
    let(:first_period_started_on) { Date.new(2025, 1, 1) }
    let(:first_period_finished_on) { Date.new(2025, 3, 31) }
    let(:second_period_started_on) { Date.new(2025, 3, 1) }
    let(:second_period_finished_on) { Date.new(2025, 6, 30) }

    it { is_expected.to be(true) }
  end

  shared_examples "when two periods are adjacent" do
    let(:first_period_started_on) { Date.new(2025, 1, 1) }
    let(:first_period_finished_on) { Date.new(2025, 3, 31) }
    let(:second_period_started_on) { Date.new(2025, 4, 1) }
    let(:second_period_finished_on) { Date.new(2025, 6, 30) }

    it { is_expected.to be(false) }
  end

  shared_examples "when two periods have a gap" do
    let(:first_period_started_on) { Date.new(2025, 1, 1) }
    let(:first_period_finished_on) { Date.new(2025, 3, 31) }
    let(:second_period_started_on) { Date.new(2025, 4, 2) }
    let(:second_period_finished_on) { Date.new(2025, 6, 30) }

    it { is_expected.to be(false) }
  end

  shared_examples "when three periods overlap transitively" do
    let(:first_period_started_on) { Date.new(2025, 1, 1) }
    let(:first_period_finished_on) { Date.new(2025, 3, 31) }
    let(:second_period_started_on) { Date.new(2025, 3, 1) }
    let(:second_period_finished_on) { Date.new(2025, 11, 30) }

    let!(:third_period) { FactoryBot.create(:mentor_at_school_period, teacher:, school:, started_on: Date.new(2025, 11, 1), finished_on: Date.new(2025, 12, 31)) }

    it { is_expected.to be(true) }
  end

  shared_examples "when two periods overlap but a third period is separate" do
    let(:first_period_started_on) { Date.new(2025, 1, 1) }
    let(:first_period_finished_on) { Date.new(2025, 3, 31) }
    let(:second_period_started_on) { Date.new(2025, 3, 1) }
    let(:second_period_finished_on) { Date.new(2025, 11, 30) }

    let!(:third_period) { FactoryBot.create(:mentor_at_school_period, teacher:, school:, started_on: Date.new(2025, 12, 15), finished_on: Date.new(2025, 12, 31)) }

    it { is_expected.to be(true) }
  end

  shared_examples "when the earliest period is ongoing" do
    let(:first_period_started_on) { Date.new(2025, 1, 1) }
    let(:first_period_finished_on) { nil }
    let(:second_period_started_on) { Date.new(2025, 4, 1) }
    let(:second_period_finished_on) { Date.new(2025, 6, 30) }

    it { is_expected.to be(true) }
  end

  shared_examples "when the latest period is ongoing" do
    let(:first_period_started_on) { Date.new(2025, 1, 1) }
    let(:first_period_finished_on) { Date.new(2025, 3, 31) }
    let(:second_period_started_on) { Date.new(2025, 4, 1) }
    let(:second_period_finished_on) { nil }

    it { is_expected.to be(false) }
  end

  describe "#any_overlapping_periods?" do
    context "mentor_at_school_periods" do
      let(:period_type) { :mentor_at_school_period }

      it_behaves_like "when two periods overlap"
      it_behaves_like "when two periods are adjacent"
      it_behaves_like "when two periods have a gap"
      it_behaves_like "when three periods overlap transitively"
      it_behaves_like "when two periods overlap but a third period is separate"
      it_behaves_like "when the earliest period is ongoing"
      it_behaves_like "when the latest period is ongoing"
    end

    context "ect_at_school_periods" do
      let(:period_type) { :ect_at_school_period }

      it_behaves_like "when two periods overlap"
      it_behaves_like "when two periods are adjacent"
      it_behaves_like "when two periods have a gap"
      it_behaves_like "when three periods overlap transitively"
      it_behaves_like "when two periods overlap but a third period is separate"
      it_behaves_like "when the earliest period is ongoing"
      it_behaves_like "when the latest period is ongoing"
    end

    context "induction_periods" do
      let(:period_type) { :induction_period }

      let!(:first_period) do
        FactoryBot.create(
          :induction_period,
          teacher:,
          started_on: first_period_started_on,
          finished_on: first_period_finished_on
        )
      end

      it_behaves_like "when two periods overlap"
      it_behaves_like "when two periods are adjacent"
      it_behaves_like "when two periods have a gap"
      it_behaves_like "when three periods overlap transitively"
      it_behaves_like "when two periods overlap but a third period is separate"

      context "when the earliest period is ongoing" do
        let!(:first_period) do
          FactoryBot.create(
            :induction_period,
            teacher:,
            number_of_terms: nil,
            started_on: Date.new(2025, 1, 1),
            finished_on: nil
          )
        end
        let(:second_period_started_on) { Date.new(2025, 4, 1) }
        let(:second_period_finished_on) { Date.new(2025, 6, 30) }

        it { is_expected.to be(true) }
      end

      context "when the latest period is ongoing" do
        let!(:second_period) do
          FactoryBot.create(
            :induction_period,
            teacher: other_teacher,
            number_of_terms: nil,
            started_on: Date.new(2025, 7, 1),
            finished_on: nil
          )
        end
        let(:first_period_started_on) { Date.new(2025, 1, 1) }
        let(:first_period_finished_on) { Date.new(2025, 6, 30) }

        it { is_expected.to be(false) }
      end
    end
  end
end
