RSpec.describe API::Teachers::EligibilityForFunding do
  describe "#eligible_for_funding" do
    subject { described_class.new(teacher:, teacher_type:).eligible_for_funding }

    context "for ECTs" do
      let(:teacher_type) { :ect }

      context "when they are not yet eligible nor ineligible" do
        let(:teacher) { FactoryBot.create(:teacher) }

        it { is_expected.to be_nil } # undetermined
      end

      context "when they are eligible" do
        let(:teacher) do
          FactoryBot.create(:teacher, ect_first_became_eligible_for_training_at: 1.day.ago)
        end

        it { is_expected.to be(true) }
      end

      context "when they are ineligible" do
        let(:teacher) do
          FactoryBot.create(:teacher, ect_became_ineligible_for_funding_on: Date.current)
        end

        it { is_expected.to be(false) }
      end

      context "when they became eligible before ineligible" do
        let(:teacher) do
          FactoryBot.create(:teacher,
                            ect_first_became_eligible_for_training_at: 2.days.ago,
                            ect_became_ineligible_for_funding_on: Date.current)
        end

        it { is_expected.to be(false) }
      end

      context "when they became ineligible before eligible" do
        let(:teacher) do
          FactoryBot.create(:teacher,
                            ect_became_ineligible_for_funding_on: 2.days.ago.to_date,
                            ect_first_became_eligible_for_training_at: Time.current)
        end

        it { is_expected.to be(false) }
      end
    end

    context "for mentors" do
      let(:teacher_type) { :mentor }

      context "when they are not yet eligible nor ineligible" do
        let(:teacher) { FactoryBot.create(:teacher) }

        it { is_expected.to be_nil } # undetermined
      end

      context "when they are eligible" do
        let(:teacher) do
          FactoryBot.create(:teacher, mentor_first_became_eligible_for_training_at: 1.day.ago)
        end

        it { is_expected.to be(true) }
      end

      context "when they are ineligible" do
        let(:teacher) do
          FactoryBot.create(:teacher,
                            mentor_became_ineligible_for_funding_on: Date.current,
                            mentor_became_ineligible_for_funding_reason: "started_not_completed")
        end

        it { is_expected.to be(false) }
      end

      context "when they became eligible before ineligible" do
        let(:teacher) do
          FactoryBot.create(:teacher,
                            mentor_first_became_eligible_for_training_at: 2.days.ago,
                            mentor_became_ineligible_for_funding_on: Date.current,
                            mentor_became_ineligible_for_funding_reason: "completed_declaration_received")
        end

        it { is_expected.to be(false) }
      end

      context "when they became ineligible before eligible" do
        let(:teacher) do
          FactoryBot.create(:teacher,
                            mentor_became_ineligible_for_funding_on: 2.days.ago.to_date,
                            mentor_became_ineligible_for_funding_reason: "completed_during_early_roll_out",
                            mentor_first_became_eligible_for_training_at: Time.current)
        end

        it { is_expected.to be(false) }
      end
    end
  end
end
