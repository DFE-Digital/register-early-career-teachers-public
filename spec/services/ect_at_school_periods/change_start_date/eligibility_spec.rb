RSpec.describe ECTAtSchoolPeriods::ChangeStartDate::Eligibility do
  subject(:eligibility) do
    described_class.new(ect_at_school_period:)
  end

  describe "#eligible?" do
    let(:school) { FactoryBot.create(:school) }
    let(:teacher) { FactoryBot.create(:teacher) }

    let(:ect_at_school_period) do
      FactoryBot.create(
        :ect_at_school_period,
        :unfinished,
        school:,
        teacher:,
        started_on: Date.new(2026, 9, 1)
      )
    end

    context "when this is the latest ECT at-school period" do
      context "with exactly one training period" do
        before do
          FactoryBot.create(
            :training_period,
            :school_led,
            :for_ect,
            :unfinished,
            ect_at_school_period:,
            started_on: ect_at_school_period.started_on
          )
        end

        it "is eligible" do
          expect(eligibility).to be_eligible
        end
      end

      context "without a training period" do
        it "is not eligible" do
          expect(eligibility).not_to be_eligible
        end
      end

      context "with multiple training periods" do
        before do
          FactoryBot.create(
            :training_period,
            :school_led,
            :for_ect,
            ect_at_school_period:,
            started_on: Date.new(2026, 9, 1),
            finished_on: Date.new(2026, 9, 30)
          )

          FactoryBot.create(
            :training_period,
            :school_led,
            :for_ect,
            :unfinished,
            ect_at_school_period:,
            started_on: Date.new(2026, 10, 1)
          )
        end

        it "is not eligible" do
          expect(eligibility).not_to be_eligible
        end
      end
    end

    context "when this is not the latest ECT at-school period" do
      let(:ect_at_school_period) do
        FactoryBot.create(
          :ect_at_school_period,
          school:,
          teacher:,
          started_on: Date.new(2025, 9, 1),
          finished_on: Date.new(2026, 8, 31)
        )
      end

      before do
        FactoryBot.create(
          :training_period,
          :school_led,
          :for_ect,
          ect_at_school_period:,
          started_on: Date.new(2025, 9, 1),
          finished_on: Date.new(2026, 8, 31)
        )

        FactoryBot.create(
          :ect_at_school_period,
          :unfinished,
          school:,
          teacher:,
          started_on: Date.new(2026, 9, 1)
        )
      end

      it "is not eligible" do
        expect(eligibility).not_to be_eligible
      end
    end
  end
end
