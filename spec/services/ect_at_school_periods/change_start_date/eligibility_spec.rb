RSpec.describe ECTAtSchoolPeriods::ChangeStartDate::Eligibility do
  subject(:eligibility) do
    described_class.new(ect_at_school_period:)
  end

  describe "#eligible?" do
    let(:ect_at_school_period) do
      FactoryBot.create(:ect_at_school_period, :unfinished)
    end

    context "when this is the latest ECT at-school period" do
      context "with exactly one training period" do
        let!(:training_period) do
          FactoryBot.create(
            :training_period,
            :school_led,
            :for_ect,
            :unfinished,
            ect_at_school_period:
          )
        end

        context "without a mentorship period" do
          it { is_expected.to be_eligible }
        end

        context "with one mentorship period" do
          let!(:mentorship_period) do
            FactoryBot.create(:mentorship_period, mentee: ect_at_school_period)
          end

          it { is_expected.to be_eligible }
        end

        context "with multiple mentorship periods" do
          let!(:mentorship_period) do
            FactoryBot.create(:mentorship_period, mentee: ect_at_school_period)
          end
          let!(:second_mentor_at_school_period) do
            FactoryBot.create(
              :mentor_at_school_period,
              :unfinished,
              school: ect_at_school_period.school
            )
          end
          let!(:second_mentorship_period) do
            FactoryBot.create(
              :mentorship_period,
              :unfinished,
              mentee: ect_at_school_period,
              mentor: second_mentor_at_school_period,
              started_on: mentorship_period.finished_on.next_day
            )
          end

          it { is_expected.not_to be_eligible }
        end
      end

      context "without a training period" do
        it { is_expected.not_to be_eligible }
      end

      context "with multiple training periods" do
        let!(:training_period) do
          FactoryBot.create(
            :training_period,
            :school_led,
            :for_ect,
            ect_at_school_period:
          )
        end
        let!(:second_training_period) do
          FactoryBot.create(
            :training_period,
            :school_led,
            :for_ect,
            :unfinished,
            ect_at_school_period:,
            started_on: training_period.finished_on.next_day
          )
        end

        it { is_expected.not_to be_eligible }
      end
    end

    context "when this is not the latest ECT at-school period" do
      let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period) }
      let!(:training_period) do
        FactoryBot.create(
          :training_period,
          :school_led,
          :for_ect,
          ect_at_school_period:
        )
      end
      let!(:latest_ect_at_school_period) do
        FactoryBot.create(
          :ect_at_school_period,
          :unfinished,
          teacher: ect_at_school_period.teacher,
          started_on: ect_at_school_period.finished_on.next_day
        )
      end

      it { is_expected.not_to be_eligible }
    end
  end
end
