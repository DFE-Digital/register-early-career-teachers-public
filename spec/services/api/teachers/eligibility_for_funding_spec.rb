RSpec.describe API::Teachers::EligibilityForFunding do
  describe "#eligible?" do
    subject { described_class.new(teacher:, teacher_type:).eligible? }

    context "for ECTs" do
      let(:teacher_type) { :ect }

      context "before ect_first_became_eligible_for_training_at or ect_became_ineligible_for_funding_on becomes filled" do
        let(:teacher) { FactoryBot.create(:teacher) }

        it { is_expected.to be_nil }
      end

      context "when ect_first_became_eligible_for_training_at is populated before ect_became_ineligible_for_funding_on" do
        let(:teacher) do
          FactoryBot.create(:teacher,
                            ect_first_became_eligible_for_training_at: 2.days.ago,
                            ect_became_ineligible_for_funding_on: Date.current)
        end

        it { is_expected.to be true }
      end

      context "when only ect_first_became_eligible_for_training_at is populated" do
        let(:teacher) do
          FactoryBot.create(:teacher, ect_first_became_eligible_for_training_at: 1.day.ago)
        end

        it { is_expected.to be true }
      end

      context "when ect_became_ineligible_for_funding_on is populated before ect_first_became_eligible_for_training_at" do
        let(:teacher) do
          FactoryBot.create(:teacher,
                            ect_became_ineligible_for_funding_on: 2.days.ago.to_date,
                            ect_first_became_eligible_for_training_at: Time.current)
        end

        it { is_expected.to be false }
      end

      context "when only ect_became_ineligible_for_funding_on is populated" do
        let(:teacher) do
          FactoryBot.create(:teacher, ect_became_ineligible_for_funding_on: Date.current)
        end

        it { is_expected.to be false }
      end
    end

    context "for mentors" do
      let(:teacher_type) { :mentor }

      context "before mentor_first_became_eligible_for_training_at or mentor_became_ineligible_for_funding_on becomes filled" do
        let(:teacher) { FactoryBot.create(:teacher) }

        it { is_expected.to be_nil }
      end

      context "when mentor_first_became_eligible_for_training_at is populated before mentor_became_ineligible_for_funding_on" do
        let(:teacher) do
          FactoryBot.create(:teacher,
                            mentor_first_became_eligible_for_training_at: 2.days.ago,
                            mentor_became_ineligible_for_funding_on: Date.current,
                            mentor_became_ineligible_for_funding_reason: "completed_declaration_received")
        end

        it { is_expected.to be true }
      end

      context "when only mentor_first_became_eligible_for_training_at is populated" do
        let(:teacher) do
          FactoryBot.create(:teacher, mentor_first_became_eligible_for_training_at: 1.day.ago)
        end

        it { is_expected.to be true }
      end

      context "when mentor_became_ineligible_for_funding_on is populated before mentor_first_became_eligible_for_training_at" do
        let(:teacher) do
          FactoryBot.create(:teacher,
                            mentor_became_ineligible_for_funding_on: 2.days.ago.to_date,
                            mentor_became_ineligible_for_funding_reason: "completed_during_early_roll_out",
                            mentor_first_became_eligible_for_training_at: Time.current)
        end

        it { is_expected.to be false }
      end

      context "when only mentor_became_ineligible_for_funding_on is populated" do
        let(:teacher) do
          FactoryBot.create(:teacher,
                            mentor_became_ineligible_for_funding_on: Date.current,
                            mentor_became_ineligible_for_funding_reason: "started_not_completed")
        end

        it { is_expected.to be false }
      end
    end
  end
end
