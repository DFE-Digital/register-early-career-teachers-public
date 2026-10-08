RSpec.describe Teachers::MergeTRN::TrainingPeriods::Merge do
  subject(:service) do
    described_class.call(
      periods:,
      destination:
    )
  end

  let(:period_type) { :training_period }
  let(:tags) { [:for_ect] }

  include_context "a mergeable period"

  describe "#call" do
    let(:source_ect_period) do
      FactoryBot.create(:ect_at_school_period,
                        teacher: source,
                        school:,
                        started_on: first_period_started_on,
                        finished_on: first_period_finished_on)
    end

    let(:destination_ect_period) do
      FactoryBot.create(:ect_at_school_period,
                        teacher: destination,
                        school:,
                        started_on: first_period_started_on,
                        finished_on: first_period_finished_on)
    end

    let(:school_partnership) { FactoryBot.create(:school_partnership, :for_year, year: 2024) }
    let(:source_attrs) { { ect_at_school_period: source_ect_period, school_partnership: } }
    let(:destination_attrs) { { ect_at_school_period: destination_ect_period, school_partnership: } }

    it_behaves_like "it merges periods"

    context "when there are declarations" do
      let!(:declaration) { FactoryBot.create(:declaration, training_period: first_period) }

      it "reassigns the training_period to the destination period's teacher" do
        first_period.reload

        expect { service }.to change { declaration.reload.training_period }.to(destination_period)
      end
    end

    context "when the periods are for different partnerships" do
      let(:other_school_partnership) { FactoryBot.create(:school_partnership, :for_year, year: 2024) }
      let(:destination_attrs) do
        { ect_at_school_period: destination_ect_period, school_partnership: other_school_partnership }
      end
      let(:source_attrs) { { ect_at_school_period: source_ect_period, school_partnership: } }

      it "raises a CannotMergePeriods error" do
        expect {
          service
        }.to raise_error(Teachers::MergeTRN::TrainingPeriods::Merge::CannotMergePeriods,
                         "Periods have different school partnerships")
      end
    end

    context "when the periods have different expressions of interest" do
      let(:destination_attrs) { { ect_at_school_period: destination_ect_period } }
      let(:source_attrs) { { ect_at_school_period: source_ect_period } }
      let(:tags) { %i[for_ect with_only_expression_of_interest] }

      it "raises a CannotMergePeriods error" do
        expect {
          service
        }.to raise_error(Teachers::MergeTRN::TrainingPeriods::Merge::CannotMergePeriods,
                         "Periods have different expression of interests")
      end
    end

    context "when ther periods have different withdrawal reasons" do
      let(:destination_attrs) do
        {
          ect_at_school_period: destination_ect_period,
          school_partnership:,
          withdrawal_reason: :left_teaching_profession,
          withdrawn_at: second_period_finished_on
        }
      end

      let(:source_attrs) { { ect_at_school_period: source_ect_period, school_partnership: } }

      it "raises a CannotMergePeriods error" do
        expect {
          service
        }.to raise_error(Teachers::MergeTRN::TrainingPeriods::Merge::CannotMergePeriods,
                         "Periods have different withdrawal reasons")
      end
    end

    context "when ther periods have different deferral reasons" do
      let(:destination_attrs) do
        {
          ect_at_school_period: destination_ect_period,
          school_partnership:,
          deferral_reason: :career_break,
          deferred_at: second_period_finished_on
        }
      end

      let(:source_attrs) { { ect_at_school_period: source_ect_period, school_partnership: } }

      it "raises a CannotMergePeriods error" do
        expect {
          service
        }.to raise_error(Teachers::MergeTRN::TrainingPeriods::Merge::CannotMergePeriods,
                         "Periods have different deferral reasons")
      end
    end

    context "when the periods have different schedules" do
      let(:tags) { %i[for_ect with_schedule] }
      let(:lead_provider) { school_partnership.lead_provider }
      let(:delivery_partner) { school_partnership.delivery_partner }
      let(:other_school_partnership) do
        FactoryBot.create(:school_partnership, :for_year, year: 2023, lead_provider:, delivery_partner:)
      end
      let(:destination_attrs) do
        { ect_at_school_period: destination_ect_period, school_partnership: other_school_partnership }
      end

      it "raises a CannotMergePeriods error" do
        expect {
          service
        }.to raise_error(Teachers::MergeTRN::TrainingPeriods::Merge::CannotMergePeriods,
                         "Periods have different schedules")
      end
    end
  end
end
