RSpec.describe Teachers::TRN::TrainingPeriods::Merge do
  subject(:service) do
    described_class.call(
      periods:,
      destination:
    )
  end

  let(:period_type) { :training_period }
  let(:traits) { [:for_ect] }

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

    let(:school_partnership) { FactoryBot.create(:school_partnership, :for_year, year: 2024, school:) }
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
      let(:other_school_partnership) do
        FactoryBot.create(:school_partnership, :with_framework_agreement,
                          school:,
                          framework_agreement: school_partnership.framework_agreement)
      end
      let(:destination_attrs) do
        { ect_at_school_period: destination_ect_period, school_partnership: other_school_partnership }
      end

      it "raises a CannotMergePeriods error" do
        expect {
          service
        }.to raise_error(Teachers::TRN::TrainingPeriods::Merge::CannotMergePeriods,
                         "Periods have different school partnerships")
      end
    end

    context "when the periods have matching school partnerships but different expressions of interest" do
      let(:source_expression_of_interest) do
        FactoryBot.create(:framework_agreement,
                          contract_period: school_partnership.contract_period)
      end
      let(:destination_expression_of_interest) do
        FactoryBot.create(:framework_agreement,
                          contract_period: school_partnership.contract_period)
      end

      let(:source_attrs) do
        {
          ect_at_school_period: source_ect_period,
          school_partnership:,
          expression_of_interest: source_expression_of_interest
        }
      end

      let(:destination_attrs) do
        {
          ect_at_school_period: destination_ect_period,
          school_partnership:,
          expression_of_interest: destination_expression_of_interest
        }
      end

      it_behaves_like "it merges periods"

      it "records each period's original expression of interest in the merge event" do
        expected_expression_of_interest_ids = [
          source_expression_of_interest.id,
          destination_expression_of_interest.id
        ]

        service

        event = Event.where(event_type: "teacher_training_periods_merged").sole

        expect(
          event.metadata["periods"].map { |period| period["expression_of_interest_id"] }
        ).to match_array(expected_expression_of_interest_ids)
      end

      context "when the periods have different withdrawal reasons" do
        let(:destination_attrs) do
          {
            ect_at_school_period: destination_ect_period,
            school_partnership:,
            expression_of_interest: destination_expression_of_interest,
            withdrawal_reason: :left_teaching_profession,
            withdrawn_at: second_period_finished_on
          }
        end

        it "raises a CannotMergePeriods error" do
          expect {
            service
          }.to raise_error(Teachers::TRN::TrainingPeriods::Merge::CannotMergePeriods,
                           "Periods have different withdrawal reasons")
        end
      end
    end

    context "when the source has only an expression of interest matching the destination's school partnership" do
      let(:expression_of_interest) do
        FactoryBot.create(:framework_agreement,
                          lead_provider: school_partnership.lead_provider,
                          contract_period: school_partnership.contract_period)
      end

      let(:source_attrs) do
        {
          ect_at_school_period: source_ect_period,
          school_partnership: nil,
          expression_of_interest:
        }
      end

      it_behaves_like "it merges periods"

      it "retains the school partnership on the destination period" do
        service

        expect(destination_period.reload.school_partnership).to eq(school_partnership)
      end

      it "records the retained school partnership in the merge event" do
        service

        event = Event.where(event_type: "teacher_training_periods_merged").sole

        expect(event.metadata["retained_school_partnership_id"]).to eq(school_partnership.id)
      end

      it "does not record a school partnership assignment event" do
        expect {
          service
        }.not_to(change do
          Event.where(event_type: "training_period_assigned_to_school_partnership").count
        end)
      end

      context "when the expression of interest has a different lead provider" do
        let(:other_lead_provider) { FactoryBot.create(:lead_provider) }

        let(:expression_of_interest) do
          FactoryBot.create(:framework_agreement,
                            lead_provider: other_lead_provider,
                            contract_period: school_partnership.contract_period)
        end

        it "raises a CannotMergePeriods error" do
          expect {
            service
          }.to raise_error(Teachers::TRN::TrainingPeriods::Merge::CannotMergePeriods,
                           "Periods have different expression of interests")
        end
      end

      context "when the expression of interest has a different contract period" do
        let(:expression_of_interest) do
          FactoryBot.create(:framework_agreement, :for_year,
                            year: 2023,
                            lead_provider: school_partnership.lead_provider)
        end

        it "raises a CannotMergePeriods error" do
          expect {
            service
          }.to raise_error(Teachers::TRN::TrainingPeriods::Merge::CannotMergePeriods,
                           "Periods have different expression of interests")
        end
      end
    end

    context "when the destination has only an expression of interest matching the source's school partnership" do
      let(:expression_of_interest) do
        FactoryBot.create(:framework_agreement,
                          lead_provider: school_partnership.lead_provider,
                          contract_period: school_partnership.contract_period)
      end

      let(:destination_attrs) do
        {
          ect_at_school_period: destination_ect_period,
          school_partnership: nil,
          expression_of_interest:
        }
      end

      it_behaves_like "it merges periods"

      it "retains the school partnership on the destination period" do
        service

        expect(destination_period.reload.school_partnership).to eq(school_partnership)
      end

      it "retains the expression of interest on the destination period" do
        service

        expect(destination_period.reload.expression_of_interest).to eq(expression_of_interest)
      end

      it "records a school partnership assignment event" do
        service

        event = Event.where(
          event_type: "training_period_assigned_to_school_partnership"
        ).sole

        expect(event).to have_attributes(
          training_period: destination_period,
          school_partnership:
        )
      end

      it "records the original partnerships and the retained partnership in the merge event" do
        original_partnerships = [
          {
            "id" => source_period.id,
            "school_partnership_id" => school_partnership.id
          },
          {
            "id" => destination_period.id,
            "school_partnership_id" => nil
          }
        ]

        service

        event = Event.where(event_type: "teacher_training_periods_merged").sole

        recorded_partnerships = event.metadata["periods"].map do |period|
          period.slice("id", "school_partnership_id")
        end

        expect(recorded_partnerships).to match_array(original_partnerships)
        expect(event.metadata["retained_school_partnership_id"]).to eq(school_partnership.id)
      end
    end

    context "when neither period has a school partnership and their expressions of interest match" do
      let(:expression_of_interest) { FactoryBot.create(:framework_agreement) }
      let(:source_attrs) do
        {
          ect_at_school_period: source_ect_period,
          school_partnership: nil,
          expression_of_interest:
        }
      end
      let(:destination_attrs) do
        {
          ect_at_school_period: destination_ect_period,
          school_partnership: nil,
          expression_of_interest:
        }
      end

      it_behaves_like "it merges periods"
    end

    context "when the periods have different expressions of interest" do
      let(:destination_attrs) { { ect_at_school_period: destination_ect_period } }
      let(:source_attrs) { { ect_at_school_period: source_ect_period } }
      let(:traits) { %i[for_ect with_only_expression_of_interest] }

      it "raises a CannotMergePeriods error" do
        expect {
          service
        }.to raise_error(Teachers::TRN::TrainingPeriods::Merge::CannotMergePeriods,
                         "Periods have different expression of interests")
      end
    end

    context "when both periods have school-led training programmes" do
      let(:traits) { %i[for_ect school_led] }

      let(:source_attrs) do
        { ect_at_school_period: source_ect_period }
      end

      let(:destination_attrs) do
        { ect_at_school_period: destination_ect_period }
      end

      it_behaves_like "it merges periods"
    end

    context "when the periods have different training_programmes" do
      let!(:second_period) do
        FactoryBot.create(
          :training_period,
          :school_led,
          ect_at_school_period: destination_ect_period,
          started_on: second_period_started_on,
          finished_on: second_period_finished_on
        )
      end

      it "raises a CannotMergePeriods error" do
        expect {
          service
        }.to raise_error(Teachers::TRN::TrainingPeriods::Merge::CannotMergePeriods,
                         "Periods have different training programmes")
      end
    end

    context "when their periods have different withdrawal reasons" do
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
        }.to raise_error(Teachers::TRN::TrainingPeriods::Merge::CannotMergePeriods,
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
        }.to raise_error(Teachers::TRN::TrainingPeriods::Merge::CannotMergePeriods,
                         "Periods have different deferral reasons")
      end
    end

    context "when the periods have different schedules" do
      let(:traits) { %i[for_ect with_schedule] }
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
        }.to raise_error(Teachers::TRN::TrainingPeriods::Merge::CannotMergePeriods,
                         "Periods have different schedules")
      end
    end
  end
end
