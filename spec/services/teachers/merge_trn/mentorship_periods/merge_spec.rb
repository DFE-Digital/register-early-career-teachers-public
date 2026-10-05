RSpec.describe Teachers::MergeTRN::MentorshipPeriods::Merge do
  subject(:service) do
    described_class.call(
      periods:,
      destination:
    )
  end

  describe "#call" do
    include_context "a mergeable period"

    let(:period_type) { :mentorship_period }
    let(:mentor) do
      FactoryBot.create(:mentor_at_school_period,
                        :unfinished,
                        school:,
                        started_on: first_period_started_on)
    end

    let(:source_ect) do
      FactoryBot.create(:ect_at_school_period,
                        teacher: source,
                        school:,
                        started_on: first_period_started_on,
                        finished_on: first_period_finished_on)
    end

    let(:destination_ect) do
      FactoryBot.create(:ect_at_school_period,
                        teacher: destination,
                        school:,
                        started_on: first_period_started_on,
                        finished_on: first_period_finished_on)
    end

    let(:source_attrs) { { mentee: source_ect, mentor: } }
    let(:destination_attrs) { { mentee: destination_ect, mentor: } }

    it_behaves_like "it merges periods"

    context "when the periods are for different mentors" do
      let(:other_mentor) do
        FactoryBot.create(:mentor_at_school_period,
                          :unfinished,
                          school:,
                          started_on: first_period_started_on)
      end

      let(:destination_attrs) { { mentee: destination_ect, mentor: other_mentor } }

      it "raises a CannotMergePeriods error" do
        expect { service }.to raise_error(Teachers::MergeTRN::MentorshipPeriods::Merge::CannotMergePeriods, "Periods have different mentors")
      end
    end
  end
end
