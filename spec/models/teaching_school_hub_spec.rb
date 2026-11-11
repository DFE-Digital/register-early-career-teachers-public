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
    let(:provisioning_school_1) { FactoryBot.create(:school, :eligible) }
    let(:provisioning_school_2) { FactoryBot.create(:school, :eligible) }
    let(:provisioning_school_3) { FactoryBot.create(:school, :eligible) }
    let(:region_north) { FactoryBot.create(:region, code: "R1") }
    let(:region_south) { FactoryBot.create(:region, code: "R2") }

    let(:first_period) do
      FactoryBot.create(:appropriate_body_period, :teaching_school_hub,
                        teaching_school_hub:,
                        provisioning_school: provisioning_school_1,
                        name: "First Body")
    end

    let(:second_period) do
      FactoryBot.create(:appropriate_body_period, :teaching_school_hub,
                        teaching_school_hub:,
                        provisioning_school: provisioning_school_2,
                        name: "Second Body")
    end

    before do
      FactoryBot.create(:region_award, appropriate_body_period: first_period, region: region_north, school: provisioning_school_1)
      FactoryBot.create(:region_award, appropriate_body_period: second_period, region: region_south, school: provisioning_school_2)
    end

    it "combines the codes across every period" do
      expect(region_codes).to contain_exactly("R1", "R2")
    end

    it "does not include codes awarded to another hub body" do
      other_hub = FactoryBot.create(:teaching_school_hub)
      other_hub_body = FactoryBot.create(:appropriate_body_period, :teaching_school_hub,
                                         teaching_school_hub: other_hub,
                                         provisioning_school: provisioning_school_3,
                                         name: nil)
      FactoryBot.create(:region_award,
                        appropriate_body_period: other_hub_body,
                        region: FactoryBot.create(:region, code: "R9"),
                        school: provisioning_school_1)

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

    let(:provisioning_school_1) { FactoryBot.create(:school, :eligible) }
    let(:provisioning_school_2) { FactoryBot.create(:school, :eligible) }

    let(:first_period) do
      FactoryBot.create(:appropriate_body_period, :teaching_school_hub,
                        teaching_school_hub:,
                        provisioning_school: provisioning_school_1,
                        name: "First Body")
    end
    let(:second_period) do
      FactoryBot.create(:appropriate_body_period, :teaching_school_hub,
                        teaching_school_hub:,
                        provisioning_school: provisioning_school_2,
                        name: "Second Body")
    end
    let(:inactive_second_period) do
      FactoryBot.create(:appropriate_body_period, :teaching_school_hub, :cannot_sign_in,
                        teaching_school_hub:,
                        provisioning_school: provisioning_school_2,
                        name: "Second Body",
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
