RSpec.describe Teachers::MergeTRN::MentorshipPeriods::Overlapping do
  subject { described_class.find(periods:) }

  let(:period_type) { :mentorship_period }
  let(:tags) { [] }

  include_context "overlapping periods"

  # If we have two TRNs being merged, each period could have an ect_at_school_period
  # which is associated with the same mentor, through two mentorship_periods
  # In that case the mentorship_periods could overlap
  # However, if the two TRNs being merged have mentor_at_school_periods, then there cannot be
  # overlapping mentorship_periods relating to those and the same ECT,
  # because an ECT can only have one mentorship_period at a time.

  describe "#find" do
    let(:other_teacher) { FactoryBot.create(:teacher) }
    let(:mentor) do
      FactoryBot.create(:mentor_at_school_period,
                        :unfinished,
                        teacher: other_teacher,
                        school:,
                        started_on: first_period_started_on)
    end
    let(:source_mentee_period) do
      FactoryBot.create(:ect_at_school_period,
                        teacher: source,
                        school:,
                        started_on: first_period_started_on,
                        finished_on: third_period_finished_on)
    end
    let(:destination_mentee_period) do
      FactoryBot.create(:ect_at_school_period,
                        teacher: destination,
                        school:,
                        started_on: second_period_started_on,
                        finished_on: fourth_period_finished_on)
    end
    let(:source_attrs) { { mentee: source_mentee_period, mentor: } }
    let(:destination_attrs) { { mentee: destination_mentee_period, mentor: } }

    it_behaves_like "it identifies overlapping periods"
    it_behaves_like "it guards against invalid periods"
  end
end
