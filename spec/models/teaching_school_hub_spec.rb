RSpec.describe TeachingSchoolHub do
  describe "validations" do
    subject(:teaching_school_hub) do
      FactoryBot.build(:teaching_school_hub)
    end

    it { is_expected.to validate_presence_of(:name) }

    it { is_expected.to validate_uniqueness_of(:name) }
  end

  describe "normalizing" do
    subject(:teaching_school_hub) { FactoryBot.create(:teaching_school_hub, name: "  Bright   Futures  ") }

    it "removes leading, trailing and repeated spaces from the name" do
      expect(teaching_school_hub.name).to eq("Bright Futures")
    end
  end

  describe "#region_codes" do
    subject(:region_codes) { teaching_school_hub.region_codes }

    let(:teaching_school_hub) { FactoryBot.create(:teaching_school_hub) }
    let(:school) { FactoryBot.create(:school, :eligible) }
    let(:region_north) { FactoryBot.create(:region, code: "R1") }
    let(:region_south) { FactoryBot.create(:region, code: "R2") }

    let(:first_period) do
      FactoryBot.create(
        :appropriate_body_period,
        :teaching_school_hub,
        teaching_school_hub:,
        provisioning_school: school,
        name: "First Period"
      )
    end

    let(:second_period) do
      FactoryBot.create(
        :appropriate_body_period,
        :teaching_school_hub,
        teaching_school_hub:,
        provisioning_school: school,
        name: "Second Period"
      )
    end

    before do
      FactoryBot.create(:region_award, appropriate_body_period: first_period, region: region_north, school:)
      FactoryBot.create(:region_award, appropriate_body_period: second_period, region: region_south, school:)
    end

    it "combines the codes across every period" do
      expect(region_codes).to contain_exactly("R1", "R2")
    end

    it "does not include codes awarded to another hub" do
      other_period = FactoryBot.create(
        :appropriate_body_period,
        :teaching_school_hub,
        teaching_school_hub: FactoryBot.create(:teaching_school_hub),
        provisioning_school: school,
        name: "Other Period"
      )
      FactoryBot.create(
        :region_award,
        appropriate_body_period: other_period,
        region: FactoryBot.create(:region, code: "R9"),
        school:
      )

      expect(region_codes).to contain_exactly("R1", "R2")
    end

    context "when a region award has been deactivated" do
      before do
        first_period.region_awards.first.update!(deactivated_at: Time.current, deactivation_reason: "no longer awarded")
      end

      it "excludes its code" do
        expect(region_codes).to contain_exactly("R2")
      end
    end
  end

  describe "#has_multiple_active_appropriate_body_periods?" do
    subject(:teaching_school_hub) { FactoryBot.create(:teaching_school_hub) }

    let(:provisioning_school) { FactoryBot.create(:school, :eligible) }

    let(:first_period) do
      FactoryBot.create(:appropriate_body_period, :teaching_school_hub,
                        teaching_school_hub:,
                        provisioning_school:,
                        name: "First Period")
    end
    let(:second_period) do
      FactoryBot.create(:appropriate_body_period, :teaching_school_hub,
                        teaching_school_hub:,
                        provisioning_school:,
                        name: "Second Period")
    end
    let(:inactive_second_period) do
      FactoryBot.create(:appropriate_body_period, :teaching_school_hub,
                        teaching_school_hub:,
                        provisioning_school:,
                        name: "Second Period",
                        finished_on: 1.year.ago)
    end

    context "when the hub has a single active period" do
      before { first_period }

      it { is_expected.not_to have_multiple_active_appropriate_body_periods }
    end

    context "when the hub has more than one active period" do
      before do
        first_period
        second_period
      end

      it { is_expected.to have_multiple_active_appropriate_body_periods }
    end

    context "when the hub has active and inactive periods" do
      before do
        first_period
        inactive_second_period
      end

      it { is_expected.not_to have_multiple_active_appropriate_body_periods }
    end
  end
end
