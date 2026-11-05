RSpec.describe Teachers::TRN::Eligibility do
  include_context "a teacher merged in TRS"

  let(:teacher) { source }

  describe "#can_be_replaced?" do
    subject(:can_be_replaced) { described_class.new(teacher:).can_be_replaced? }

    let(:redirected_trn) { "1234567" }

    before do
      teacher.update!(trs_response: "permanent_redirect", trs_redirected_to: redirected_trn)
    end

    context "when there is a redirected TRN" do
      it { is_expected.to be true }
    end

    context "when resolver cannot resolve a TRN" do
      let(:resolver) { instance_double(Teachers::TRN::Resolver, new_trn: nil) }

      before do
        allow(Teachers::TRN::Resolver).to receive(:new)
          .with(teacher:, proposed_trn: nil)
          .and_return(resolver)
      end

      it { is_expected.to be false }
    end

    context "when the redirected TRN exists in the system" do
      let(:redirected_trn) { "9999999" }
      let!(:other_teacher) { FactoryBot.create(:teacher, trn: "9999999") }

      it { is_expected.to be false }
    end

    context "when the redirected TRN is the same as the teacher's TRN" do
      let(:redirected_trn) { teacher.trn }

      it { is_expected.to be false }
    end

    context "when another teacher redirects to the target TRN" do
      before { FactoryBot.create(:teacher, :merged_in_trs, trs_redirected_to: redirected_trn) }

      it { is_expected.to be false }
    end

    context "when the teacher is not permanently redirected or deactivated" do
      let(:trs_response) { "ok" }
      let(:trs_redirected_to) { nil }

      before do
        teacher.update!(trs_response:, trs_redirected_to:)
      end

      it { is_expected.to be false }

      context "when a new TRN is supplied" do
        let(:new_trn) { "2345678" }

        it { is_expected.to be false }
      end

      context "when the teacher has a redirected TRN" do
        let(:trs_redirected_to) { "2345678" }

        it { is_expected.to be false }
      end
    end
  end

  describe "#can_be_merged?" do
    subject(:can_be_merged) { described_class.new(teacher:).can_be_merged? }

    let(:redirected_trn) { destination.trn }

    before do
      teacher.update!(trs_response: "permanent_redirect", trs_redirected_to: redirected_trn)
    end

    context "when there is a redirected TRN" do
      let(:redirected_trn) { destination.trn }

      it { is_expected.to be true }
    end

    context "when resolver cannot resolve a TRN" do
      let(:redirected_trn) { destination.trn }
      let(:resolver) { instance_double(Teachers::TRN::Resolver, new_trn: nil) }

      before do
        allow(Teachers::TRN::Resolver).to receive(:new)
          .with(teacher:, proposed_trn: nil)
          .and_return(resolver)
      end

      it { is_expected.to be false }
    end

    context "when the redirected TRN does not exist in the system" do
      let(:redirected_trn) { "9999999" }

      it { is_expected.to be false }
    end

    context "when the redirected TRN is the same as the teacher's TRN" do
      let(:redirected_trn) { teacher.trn }

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
        let(:traits) { [:for_ect] }

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
          let(:traits) { %i[for_ect with_only_expression_of_interest] }

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
        let(:traits) { [:for_mentor] }

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
          let(:traits) { %i[for_mentor with_only_expression_of_interest] }

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
