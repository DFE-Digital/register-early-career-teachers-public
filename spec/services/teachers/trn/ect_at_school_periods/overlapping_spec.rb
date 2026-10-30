RSpec.describe Teachers::TRN::ECTAtSchoolPeriods::Overlapping do
  subject { described_class.find(periods:) }

  let(:period_type) { :ect_at_school_period }
  let(:traits) { [] }

  include_context "overlapping periods"

  describe "#find" do
    it_behaves_like "it identifies overlapping periods"
    it_behaves_like "it guards against invalid periods"
    it_behaves_like "it identifies overlapping at_school periods"
  end
end
