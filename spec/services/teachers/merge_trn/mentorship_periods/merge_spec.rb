RSpec.describe Teachers::MergeTRN::MentorshipPeriods::Merge do
  subject(:service) do
    described_class.call(
      periods:,
      destination:
    )
  end

  let(:period_type) { :mentorship_period }
  let(:tags) { [] }

  include_context "a mergeable period"

  describe "#call" do
    let(:mentor) do
      FactoryBot.create(:mentor_at_school_period,
                        :unfinished,
                        school:,
                        started_on: first_period_started_on)
    end

    let(:source_mentee_period) do
      FactoryBot.create(:ect_at_school_period,
                        teacher: source,
                        school:,
                        started_on: first_period_started_on,
                        finished_on: first_period_finished_on)
    end

    let(:destination_mentee_period) do
      FactoryBot.create(:ect_at_school_period,
                        teacher: destination,
                        school:,
                        started_on: first_period_started_on,
                        finished_on: first_period_finished_on)
    end

    let(:source_attrs) { { mentee: source_mentee_period, mentor: } }
    let(:destination_attrs) { { mentee: destination_mentee_period, mentor: } }

    it_behaves_like "it merges periods"

    context "when the periods are for different mentors" do
      let(:other_mentor_period) do
        FactoryBot.create(:mentor_at_school_period,
                          :unfinished,
                          school:,
                          started_on: first_period_started_on)
      end

      let(:destination_attrs) { { mentee: destination_mentee_period, mentor: other_mentor_period } }

      it "raises a CannotMergePeriods error" do
        expect { service }.to raise_error(Teachers::MergeTRN::MentorshipPeriods::Merge::CannotMergePeriods, "Periods have different mentors")
      end
    end
  end
end
