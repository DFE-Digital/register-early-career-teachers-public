RSpec.describe Teachers::MergeTRN::TrainingPeriods::Overlapping do
  subject { described_class.find(periods:) }

  let(:period_type) { :training_period }
  let(:tags) { [:for_mentor] }

  include_context "overlapping periods"

  describe "#find" do
    let(:source_mentor_period) do
      FactoryBot.create(:mentor_at_school_period,
                        teacher: source,
                        school:,
                        started_on: first_period_started_on,
                        finished_on: third_period_finished_on)
    end
    let(:destination_mentor_period) do
      FactoryBot.create(:mentor_at_school_period,
                        teacher: destination,
                        school:,
                        started_on: second_period_started_on,
                        finished_on: fourth_period_finished_on)
    end
    let(:source_attrs) { { mentor_at_school_period: source_mentor_period } }
    let(:destination_attrs) { { mentor_at_school_period: destination_mentor_period } }

    it_behaves_like "it identifies overlapping periods"
    it_behaves_like "it guards against invalid periods"
  end
end
