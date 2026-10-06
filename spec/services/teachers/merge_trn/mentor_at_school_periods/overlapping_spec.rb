RSpec.describe Teachers::MergeTRN::MentorAtSchoolPeriods::Overlapping do
  subject { described_class.find(periods:) }

  let(:period_type) { :mentor_at_school_period }
  let(:tags) { [] }

  include_context "overlapping periods"

  describe "#find" do
    it_behaves_like "it identifies overlapping periods"
    it_behaves_like "it guards against invalid periods"
    it_behaves_like "it identifies overlapping at_school periods"

    context "when periods at different schools occur at the same time" do
      let(:third_period_started_on) { Date.new(2025, 2, 1) }
      let(:third_period_finished_on) { Date.new(2025, 4, 30) }
      let(:fourth_period_started_on) { Date.new(2025, 3, 15) }
      let(:fourth_period_finished_on) { Date.new(2025, 12, 31) }

      let(:other_school) { FactoryBot.create(:school) }

      let!(:third_period) do
        FactoryBot.create(:mentor_at_school_period,
                          teacher: source,
                          school: other_school,
                          started_on: third_period_started_on,
                          finished_on: third_period_finished_on)
      end

      let!(:fourth_period) do
        FactoryBot.create(
          :mentor_at_school_period,
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
end
