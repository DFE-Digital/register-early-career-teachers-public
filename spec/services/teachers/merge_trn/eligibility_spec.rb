RSpec.describe Teachers::MergeTRN::Eligibility do
  include_context "a teacher merged in TRS"

  let(:teacher) { source }

  describe "#can_be_merged?" do
    subject(:can_be_merged) { described_class.new(teacher:).can_be_merged? }

    context "when a merge is not required" do
      before { teacher.update!(trs_response: "ok") }

      it { is_expected.to be false }
    end

    context "when there is no redirected TRN" do
      before { teacher.update!(trs_redirected_to: nil) }

      it { is_expected.to be false }
    end

    context "when the destination does not exist" do
      let(:destination) { nil }

      it { is_expected.to be false }
    end

    context "when neither teacher has at_school periods" do
      it { is_expected.to be true }
    end

    context "when only the source has induction periods" do
      before { FactoryBot.create(:induction_period, teacher:) }

      it { is_expected.to be true }
    end

    context "when only the destination has induction periods" do
      before { FactoryBot.create(:induction_period, teacher: destination) }

      it { is_expected.to be true }
    end

    context "when both teachers have induction periods" do
      before do
        FactoryBot.create(:induction_period, teacher:)
        FactoryBot.create(:induction_period, teacher: destination)
      end

      it { is_expected.to be false }
    end

    context "when both teachers have ECT school periods" do
      let(:school) { FactoryBot.create(:school) }
      let(:destination_school) { FactoryBot.create(:school) }
      let(:destination_started_on) { Date.new(2025, 3, 1) }

      before do
        FactoryBot.create(
          :ect_at_school_period,
          teacher:,
          school:,
          started_on: Date.new(2025, 1, 1),
          finished_on: Date.new(2025, 6, 1)
        )

        FactoryBot.create(
          :ect_at_school_period,
          teacher: destination,
          school: destination_school,
          started_on: destination_started_on,
          finished_on: Date.new(2025, 12, 1)
        )
      end

      context "when they overlap at different schools" do
        it { is_expected.to be false }
      end

      context "when they do not overlap at different schools" do
        let(:destination_started_on) { Date.new(2025, 7, 1) }

        it { is_expected.to be true }
      end

      context "when they overlap at the same school" do
        let(:destination_school) { school }

        it { is_expected.to be true }
      end
    end

    context "training periods" do
      include_context "a mergeable period"

      let(:period_type) { :training_period }

      let(:lead_provider) { FactoryBot.create(:lead_provider) }
      let(:delivery_partner) { FactoryBot.create(:delivery_partner) }

      let(:school_partnership_2025) do
        FactoryBot.create(
          :school_partnership,
          :for_year,
          year: 2025,
          school:,
          lead_provider:,
          delivery_partner:
        )
      end

      let(:school_partnership_2026) do
        FactoryBot.create(
          :school_partnership,
          :for_year,
          year: 2026,
          school:,
          lead_provider:,
          delivery_partner:
        )
      end

      let(:expression_of_interest_2025) do
        FactoryBot.create(
          :framework_agreement,
          :for_year,
          year: 2025,
          lead_provider:
        )
      end

      let(:expression_of_interest_2026) do
        FactoryBot.create(
          :framework_agreement,
          :for_year,
          year: 2026,
          lead_provider:
        )
      end

      let(:first_period_started_on) { Date.new(2025, 1, 1) }
      let(:first_period_finished_on) { Date.new(2025, 6, 1) }
      let(:second_period_started_on) { Date.new(2026, 3, 1) }
      let(:second_period_finished_on) { Date.new(2026, 12, 1) }

      before do
        first_period
        second_period
      end

      context "ECT training periods" do
        let(:tags) { [:for_ect] }

        let(:source_ect_at_school_period) do
          FactoryBot.create(
            :ect_at_school_period,
            teacher: source,
            school:,
            started_on: first_period_started_on,
            finished_on: first_period_finished_on
          )
        end

        let(:destination_ect_at_school_period) do
          FactoryBot.create(
            :ect_at_school_period,
            teacher: destination,
            school:,
            started_on: second_period_started_on,
            finished_on: second_period_finished_on
          )
        end

        let(:source_attrs) do
          {
            ect_at_school_period: source_ect_at_school_period,
            school_partnership: school_partnership_2025
          }
        end

        context "when both training periods use confirmed partnerships" do
          context "when the contract periods are different" do
            let(:destination_attrs) do
              {
                ect_at_school_period: destination_ect_at_school_period,
                school_partnership: school_partnership_2026
              }
            end

            it { is_expected.to be false }
          end

          context "when the contract periods are the same" do
            let(:destination_attrs) do
              {
                ect_at_school_period: destination_ect_at_school_period,
                school_partnership: school_partnership_2025
              }
            end

            it { is_expected.to be true }
          end
        end

        context "when both training periods have only expressions of interest" do
          let(:tags) { %i[for_ect with_only_expression_of_interest] }

          let(:source_attrs) do
            {
              ect_at_school_period: source_ect_at_school_period,
              expression_of_interest: expression_of_interest_2025
            }
          end

          context "when the contract periods are different" do
            let(:destination_attrs) do
              {
                ect_at_school_period: destination_ect_at_school_period,
                expression_of_interest: expression_of_interest_2026
              }
            end

            it { is_expected.to be false }
          end

          context "when the contract periods are the same" do
            let(:destination_attrs) do
              {
                ect_at_school_period: destination_ect_at_school_period,
                expression_of_interest: expression_of_interest_2025
              }
            end

            it { is_expected.to be true }
          end
        end

        context "when only one training period is confirmed" do
          let(:first_period) do
            FactoryBot.create(
              :training_period,
              :for_ect,
              :with_only_expression_of_interest,
              ect_at_school_period: source_ect_at_school_period,
              expression_of_interest: expression_of_interest_2025,
              started_on: first_period_started_on,
              finished_on: first_period_finished_on
            )
          end

          context "when the contract periods are different" do
            let(:destination_attrs) do
              {
                ect_at_school_period: destination_ect_at_school_period,
                school_partnership: school_partnership_2026
              }
            end

            it { is_expected.to be false }
          end

          context "when the contract periods are the same" do
            let(:destination_attrs) do
              {
                ect_at_school_period: destination_ect_at_school_period,
                school_partnership: school_partnership_2025
              }
            end

            it { is_expected.to be true }
          end
        end

        context "when the training periods have different training programmes" do
          let(:first_period) do
            FactoryBot.create(
              :training_period,
              :for_ect,
              :school_led,
              ect_at_school_period: source_ect_at_school_period,
              started_on: first_period_started_on,
              finished_on: first_period_finished_on
            )
          end

          let(:destination_attrs) do
            {
              ect_at_school_period: destination_ect_at_school_period,
              school_partnership: school_partnership_2025
            }
          end

          it { is_expected.to be true }
        end
      end

      context "Mentor training periods" do
        let(:tags) { [:for_mentor] }

        let(:source_mentor_at_school_period) do
          FactoryBot.create(
            :mentor_at_school_period,
            teacher: source,
            school:,
            started_on: first_period_started_on,
            finished_on: first_period_finished_on
          )
        end

        let(:destination_mentor_at_school_period) do
          FactoryBot.create(
            :mentor_at_school_period,
            teacher: destination,
            school:,
            started_on: second_period_started_on,
            finished_on: second_period_finished_on
          )
        end

        let(:source_attrs) do
          {
            mentor_at_school_period: source_mentor_at_school_period,
            school_partnership: school_partnership_2025
          }
        end

        context "when both training periods use confirmed partnerships" do
          context "when the contract periods are different" do
            let(:destination_attrs) do
              {
                mentor_at_school_period: destination_mentor_at_school_period,
                school_partnership: school_partnership_2026
              }
            end

            it { is_expected.to be false }
          end

          context "when the contract periods are the same" do
            let(:destination_attrs) do
              {
                mentor_at_school_period: destination_mentor_at_school_period,
                school_partnership: school_partnership_2025
              }
            end

            it { is_expected.to be true }
          end
        end

        context "when both training periods have only expressions of interest" do
          let(:tags) { %i[for_mentor with_only_expression_of_interest] }

          let(:source_attrs) do
            {
              mentor_at_school_period: source_mentor_at_school_period,
              expression_of_interest: expression_of_interest_2025
            }
          end

          context "when the contract periods are different" do
            let(:destination_attrs) do
              {
                mentor_at_school_period: destination_mentor_at_school_period,
                expression_of_interest: expression_of_interest_2026
              }
            end

            it { is_expected.to be false }
          end

          context "when the contract periods are the same" do
            let(:destination_attrs) do
              {
                mentor_at_school_period: destination_mentor_at_school_period,
                expression_of_interest: expression_of_interest_2025
              }
            end

            it { is_expected.to be true }
          end
        end

        context "when only one training period is confirmed" do
          let(:first_period) do
            FactoryBot.create(
              :training_period,
              :for_mentor,
              :with_only_expression_of_interest,
              mentor_at_school_period: source_mentor_at_school_period,
              expression_of_interest: expression_of_interest_2025,
              started_on: first_period_started_on,
              finished_on: first_period_finished_on
            )
          end

          context "when the contract periods are different" do
            let(:destination_attrs) do
              {
                mentor_at_school_period: destination_mentor_at_school_period,
                school_partnership: school_partnership_2026
              }
            end

            it { is_expected.to be false }
          end

          context "when the contract periods are the same" do
            let(:destination_attrs) do
              {
                mentor_at_school_period: destination_mentor_at_school_period,
                school_partnership: school_partnership_2025
              }
            end

            it { is_expected.to be true }
          end
        end
      end
    end
  end
end
