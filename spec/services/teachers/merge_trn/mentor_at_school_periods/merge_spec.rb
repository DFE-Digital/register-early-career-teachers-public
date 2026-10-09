RSpec.describe Teachers::MergeTRN::MentorAtSchoolPeriods::Merge do
  subject(:service) do
    described_class.call(
      periods:,
      destination:
    )
  end

  let(:period_type) { :mentor_at_school_period }
  let(:tags) { [] }

  include_context "a mergeable period"

  describe "#call" do
    it_behaves_like "it merges periods"
    it_behaves_like "it moves non-overlapping training_periods"
    it_behaves_like "it merges overlapping training periods"
    it_behaves_like "it moves non-overlapping mentorship_periods"
  end
end
