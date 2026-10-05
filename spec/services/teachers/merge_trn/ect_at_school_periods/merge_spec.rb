RSpec.describe Teachers::MergeTRN::ECTAtSchoolPeriods::Merge do
  subject(:service) do
    described_class.call(
      periods:,
      destination:
    )
  end

  describe "#call" do
    include_context "a mergeable period"
    let(:period_type) { :ect_at_school_period }

    it_behaves_like "it merges periods"
    it_behaves_like "it reassigns training_periods"
    it_behaves_like "it reassigns mentorship_periods"

    context "when there are overlapping mentorship periods" do
      let(:mentor) do
        FactoryBot.create(:mentor_at_school_period,
                          :unfinished,
                          school:,
                          started_on: first_period_started_on)
      end

      let!(:source_mentorship_period) do
        FactoryBot.create(:mentorship_period,
                          mentee: source_period,
                          mentor:,
                          started_on: first_period_started_on,
                          finished_on: first_period_finished_on)
      end

      let!(:destination_mentorship_period) do
        FactoryBot.create(:mentorship_period,
                          mentee: destination_period,
                          mentor:,
                          started_on: second_period_started_on,
                          finished_on: second_period_finished_on)
      end

      it "changes the start date of the second period" do
        expect { service }.to change(destination_period, :started_on).to(first_period_started_on)
      end

      it "changes the end date of the second period" do
        expect { service }.to change(destination_period, :finished_on).to(first_period_finished_on)
      end

      # it "deletes the first period" do
      #   service

      #   expect(klass.exists?(first_period.id)).to be(false)
      # end
    end
  end
end
