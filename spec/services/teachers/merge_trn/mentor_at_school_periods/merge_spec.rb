RSpec.describe Teachers::MergeTRN::MentorAtSchoolPeriods::Merge do
  subject(:service) do
    described_class.call(
      periods:,
      destination:
    )
  end

  describe "#call" do
    include_context "a mergeable period"

    let(:period_type) { :mentor_at_school_period }

    it_behaves_like "it merges periods"
    it_behaves_like "it reassigns training_periods"
    it_behaves_like "it reassigns mentorship_periods"
  end
end
