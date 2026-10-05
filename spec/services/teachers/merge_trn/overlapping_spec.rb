RSpec.describe Teachers::MergeTRN::Overlapping do
  subject(:groups) { described_class.find(periods:) }

  let(:source) do
    FactoryBot.create(:teacher,
                      :merged_in_trs,
                      trn: source_trn,
                      trs_redirected_to: destination_trn)
  end

  let(:destination) { FactoryBot.create(:teacher, trn: destination_trn) }
  let(:school) { FactoryBot.create(:school) }

  let(:source_trn) { "654321" }
  let(:destination_trn) { "123456" }

  let(:source_attrs) { { teacher: source, school: } }
  let(:destination_attrs) { { teacher: destination, school: } }

  let(:other_school) { FactoryBot.create(:school) }
  let(:other_source_attrs) { { teacher: source, school: other_school } }
  let(:other_destination_attrs) { { teacher: destination, school: other_school } }

  let(:tags) { [] }

  let(:first_period) do
    FactoryBot.create(
      period_type,
      *tags,
      **source_attrs,
      started_on: first_period_started_on,
      finished_on: first_period_finished_on
    )
  end

  let(:second_period) do
    FactoryBot.create(
      period_type,
      *tags,
      **destination_attrs,
      started_on: second_period_started_on,
      finished_on: second_period_finished_on
    )
  end

  let(:third_period) do
    FactoryBot.create(period_type,
                      *tags,
                      **source_attrs,
                      started_on: third_period_started_on,
                      finished_on: third_period_finished_on)
  end

  let(:fourth_period) do
    FactoryBot.create(
      period_type,
      *tags,
      **destination_attrs,
      started_on: fourth_period_started_on,
      finished_on: fourth_period_finished_on
    )
  end

  shared_examples "overlapping periods" do
    let(:periods) { [first_period, second_period] }
    let(:third_period_started_on) { first_period_started_on }
    let(:third_period_finished_on) { first_period_finished_on }
    let(:fourth_period_started_on) { second_period_started_on }
    let(:fourth_period_finished_on) { second_period_finished_on }

    context "when two periods overlap" do
      let(:first_period_started_on) { Date.new(2025, 1, 1) }
      let(:first_period_finished_on) { Date.new(2025, 3, 31) }
      let(:second_period_started_on) { Date.new(2025, 3, 1) }
      let(:second_period_finished_on) { Date.new(2025, 6, 30) }

      it { is_expected.to eq([[first_period, second_period]]) }
    end

    context "when two periods are adjacent" do
      let(:first_period_started_on) { Date.new(2025, 1, 1) }
      let(:first_period_finished_on) { Date.new(2025, 3, 31) }
      let(:second_period_started_on) { Date.new(2025, 4, 1) }
      let(:second_period_finished_on) { Date.new(2025, 6, 30) }

      it { is_expected.to be_empty }
    end

    context "when two periods have a gap" do
      let(:first_period_started_on) { Date.new(2025, 1, 1) }
      let(:first_period_finished_on) { Date.new(2025, 3, 31) }
      let(:second_period_started_on) { Date.new(2025, 4, 2) }
      let(:second_period_finished_on) { Date.new(2025, 6, 30) }

      it { is_expected.to be_empty }
    end

    context "when three periods overlap transitively" do
      let(:first_period_started_on) { Date.new(2025, 1, 1) }
      let(:first_period_finished_on) { Date.new(2025, 3, 31) }
      let(:second_period_started_on) { Date.new(2025, 3, 1) }
      let(:second_period_finished_on) { Date.new(2025, 11, 30) }
      let(:third_period_started_on) { Date.new(2025, 11, 1) }
      let(:third_period_finished_on) { Date.new(2025, 12, 31) }

      let(:periods) { [first_period, second_period, third_period] }

      it { is_expected.to eq([[first_period, second_period, third_period]]) }
    end

    context "when two periods overlap but a third period is separate" do
      let(:first_period_started_on) { Date.new(2025, 1, 1) }
      let(:first_period_finished_on) { Date.new(2025, 3, 31) }
      let(:second_period_started_on) { Date.new(2025, 3, 1) }
      let(:second_period_finished_on) { Date.new(2025, 11, 30) }
      let(:third_period_started_on) { Date.new(2025, 12, 15) }
      let(:third_period_finished_on) { Date.new(2025, 12, 31) }

      let(:periods) { [first_period, second_period, third_period] }

      it { is_expected.to eq([[first_period, second_period]]) }
    end

    context "when there are two separate groups of overlapping periods" do
      let(:first_period_started_on) { Date.new(2025, 1, 1) }
      let(:first_period_finished_on) { Date.new(2025, 3, 31) }
      let(:second_period_started_on) { Date.new(2025, 3, 15) }
      let(:second_period_finished_on) { Date.new(2025, 6, 30) }
      let(:third_period_started_on) { Date.new(2025, 7, 15) }
      let(:third_period_finished_on) { Date.new(2025, 9, 30) }
      let(:fourth_period_started_on) { Date.new(2025, 9, 1) }
      let(:fourth_period_finished_on) { Date.new(2025, 12, 31) }

      let(:periods) { [first_period, second_period, third_period, fourth_period] }

      it "returns two separate merge groups" do
        expect(groups).to eq([
          [first_period, second_period],
          [third_period, fourth_period]
        ])
      end
    end

    context "when the earliest period is ongoing" do
      let(:first_period_started_on) { Date.new(2025, 1, 1) }
      let(:first_period_finished_on) { nil }
      let(:second_period_started_on) { Date.new(2025, 4, 1) }
      let(:second_period_finished_on) { Date.new(2025, 6, 30) }
      let(:fourth_period_finished_on) { nil }
      let(:first_period_number_of_terms) { nil }

      it { is_expected.to eq([[first_period, second_period]]) }
    end
  end

  shared_context "overlapping at_school periods" do
    context "when there are periods at two schools" do
      let(:first_period_started_on) { Date.new(2025, 1, 1) }
      let(:first_period_finished_on) { Date.new(2025, 3, 31) }
      let(:second_period_started_on) { Date.new(2025, 3, 1) }
      let(:second_period_finished_on) { Date.new(2025, 6, 30) }
      let(:third_period_started_on) { Date.new(2025, 7, 1) }
      let(:third_period_finished_on) { Date.new(2025, 9, 30) }
      let(:fourth_period_started_on) { Date.new(2025, 9, 1) }
      let(:fourth_period_finished_on) { Date.new(2025, 12, 31) }

      let(:third_period) do
        FactoryBot.create(period_type,
                          *tags,
                          **other_source_attrs,
                          started_on: third_period_started_on,
                          finished_on: third_period_finished_on)
      end

      let(:fourth_period) do
        FactoryBot.create(
          period_type,
          *tags,
          **other_destination_attrs,
          started_on: fourth_period_started_on,
          finished_on: fourth_period_finished_on
        )
      end

      let(:periods) { [first_period, second_period, third_period, fourth_period] }

      context "when periods at both schools overlap" do
        it "the overlapping groups at each school" do
          expect(groups).to eq([
            [first_period, second_period],
            [third_period, fourth_period]
          ])
        end
      end

      context "when there are no overlapping periods at the first school" do
        let(:second_period_started_on) { Date.new(2025, 4, 2) }

        it "does not include periods from the first school" do
          expect(subject).to eq([[third_period, fourth_period]])
        end
      end

      context "when there are no overlapping periods at the second school" do
        let(:fourth_period_started_on) { Date.new(2025, 11, 1) }

        it "does not include periods from the second school" do
          expect(subject).to eq([[first_period, second_period]])
        end
      end

      context "when there are no overlapping periods at either school" do
        let(:second_period_started_on) { Date.new(2025, 4, 2) }
        let(:fourth_period_started_on) { Date.new(2025, 11, 1) }

        it "does not include periods from either school" do
          expect(subject).to be_empty
        end
      end
    end
  end

  describe "#find" do
    context "when the periods are of different types" do
      let(:first_period) { FactoryBot.create(:mentor_at_school_period) }
      let(:second_period) { FactoryBot.create(:ect_at_school_period) }

      let(:periods) { [first_period, second_period] }

      it "raises an error" do
        expect { subject }.to raise_error(ArgumentError)
      end
    end

    context "when no periods are present" do
      let(:periods) { [] }

      it { is_expected.to be_empty }
    end

    context "mentor_at_school_periods" do
      let(:period_type) { :mentor_at_school_period }

      it_behaves_like "overlapping periods"
      it_behaves_like "overlapping at_school periods"

      context "when periods at different schools occur at the same time" do
        let(:first_period_started_on) { Date.new(2025, 1, 1) }
        let(:first_period_finished_on) { Date.new(2025, 3, 31) }
        let(:second_period_started_on) { Date.new(2025, 3, 1) }
        let(:second_period_finished_on) { Date.new(2025, 6, 30) }
        let(:third_period_started_on) { Date.new(2025, 2, 1) }
        let(:third_period_finished_on) { Date.new(2025, 4, 30) }
        let(:fourth_period_finished_on) { Date.new(2025, 12, 31) }
        let(:fourth_period_started_on) { Date.new(2025, 3, 15) }

        let(:other_school) { FactoryBot.create(:school) }

        let!(:third_period) do
          FactoryBot.create(period_type,
                            teacher: source,
                            school: other_school,
                            started_on: third_period_started_on,
                            finished_on: third_period_finished_on)
        end

        let!(:fourth_period) do
          FactoryBot.create(
            period_type,
            teacher: destination,
            school: other_school,
            started_on: fourth_period_started_on,
            finished_on: fourth_period_finished_on
          )
        end

        let(:periods) { [first_period, second_period, third_period, fourth_period] }

        it "keeps the schools in separate groups" do
          expect(subject).to eq([
            [first_period, second_period],
            [third_period, fourth_period]
          ])
        end
      end
    end

    context "ect_at_school_periods" do
      let(:period_type) { :ect_at_school_period }

      it_behaves_like "overlapping periods"
      it_behaves_like "overlapping at_school periods"
    end

    context "training_periods" do
      let(:period_type) { :training_period }
      let(:tags) { [:for_mentor] }

      let(:source_period) do
        FactoryBot.create(:mentor_at_school_period,
                          teacher: source,
                          school:,
                          started_on: first_period_started_on,
                          finished_on: third_period_finished_on)
      end

      let(:destination_period) do
        FactoryBot.create(:mentor_at_school_period,
                          teacher: destination,
                          school:,
                          started_on: second_period_started_on,
                          finished_on: fourth_period_finished_on)
      end

      let(:source_attrs) { { mentor_at_school_period: source_period } }
      let(:destination_attrs) { { mentor_at_school_period: destination_period } }

      let(:other_source_period) do
        FactoryBot.create(:mentor_at_school_period,
                          teacher: source,
                          school: other_school,
                          started_on: third_period_started_on,
                          finished_on: third_period_finished_on)
      end

      let(:other_destination_period) do
        FactoryBot.create(:mentor_at_school_period,
                          teacher: destination,
                          school: other_school,
                          started_on: fourth_period_started_on,
                          finished_on: fourth_period_finished_on)
      end

      let(:other_source_attrs) { { mentor_at_school_period: other_source_period } }
      let(:other_destination_attrs) { { mentor_at_school_period: other_destination_period } }

      it_behaves_like "overlapping periods"
    end

    # If we have two TRNs being merged, each period could have an ect_at_school_period
    # which is associated with the same mentor, through two mentorship_periods
    # In that case the mentorship_periods could overlap
    # However, if the two TRNs being merged have mentor_at_school_periods, then there cannot be
    # overlapping mentorship_periods relating to those and the same ECT,
    # because an ECT can only have one mentorship_period at a time.
    context "mentorship_periods" do
      let(:period_type) { :mentorship_period }
      let(:other_teacher) { FactoryBot.create(:teacher) }

      let(:mentor) do
        FactoryBot.create(:mentor_at_school_period,
                          :unfinished,
                          teacher: other_teacher,
                          school:,
                          started_on: first_period_started_on)
      end

      let(:source_period) do
        FactoryBot.create(:ect_at_school_period,
                          teacher: source,
                          school:,
                          started_on: first_period_started_on,
                          finished_on: third_period_finished_on)
      end

      let(:destination_period) do
        FactoryBot.create(:ect_at_school_period,
                          teacher: destination,
                          school:,
                          started_on: second_period_started_on,
                          finished_on: fourth_period_finished_on)
      end

      let(:source_attrs) { { mentee: source_period, mentor: } }
      let(:destination_attrs) { { mentee: destination_period, mentor: } }

      it_behaves_like "overlapping periods"
    end
  end

  def max_date
    dates = [first_period_finished_on, second_period_finished_on, third_period_finished_on, fourth_period_finished_on]

    return nil if dates.any?(&:nil?)

    dates.compact.max
  end
end
