RSpec.describe TeachingSchoolHub do
  describe "associations" do
    describe "#appropriate_body_periods" do
      subject(:periods) { teaching_school_hub.appropriate_body_periods }

      let(:teaching_school_hub) { FactoryBot.create(:teaching_school_hub) }

      let!(:finished_later) do
        FactoryBot.create(:appropriate_body_period, :teaching_school_hub,
                          teaching_school_hub:,
                          name: "Previous",
                          finished_on: 1.year.ago)
      end

      let!(:finished_earlier) do
        FactoryBot.create(:appropriate_body_period, :teaching_school_hub,
                          teaching_school_hub:,
                          name: "First",
                          finished_on: 2.years.ago)
      end

      let!(:ongoing) do
        FactoryBot.create(:appropriate_body_period, :teaching_school_hub,
                          teaching_school_hub:,
                          name: "Current")
      end

      it "returns active periods first" do
        expect(periods.map(&:name)).to eq(%w[Current Previous First])
      end
    end
  end

  describe "validations" do
    subject(:teaching_school_hub) { FactoryBot.build(:teaching_school_hub, name:) }

    let(:name) { nil }

    it { is_expected.to validate_presence_of(:name) }

    context "when it is named" do
      let(:name) { "North West Hub" }

      it { is_expected.to validate_uniqueness_of(:name) }
    end

    context "when an ongoing appropriate body period uses the name" do
      let!(:period) { FactoryBot.create(:appropriate_body_period, name:) }
      let(:name) { "North West Hub" }

      it { is_expected.to have_error(:name, "is already used by an ongoing appropriate body.") }

      context "while the period runs to a future end date" do
        before { period.update!(finished_on: 1.year.from_now.to_date) }

        it { is_expected.to have_error(:name, "is already used by an ongoing appropriate body.") }
      end

      context "once the period has finished" do
        before { period.update!(finished_on: Date.yesterday) }

        it { is_expected.to be_valid }
      end
    end

    context "when a national body is actively using the name" do
      subject!(:teaching_school_hub) { FactoryBot.create(:teaching_school_hub, name: "North West Hub") }

      before do
        FactoryBot.create(:appropriate_body_period, :national, :nameless,
                          national_body: FactoryBot.create(:national_body, name: "North West Hub"))
      end

      it { is_expected.to have_error(:name, "is already used by an ongoing appropriate body.") }
    end
  end

  describe "normalizing" do
    subject(:teaching_school_hub) { FactoryBot.create(:teaching_school_hub, name:) }

    let(:name) { "  Bright   Futures  " }

    it { is_expected.to have_attributes(name: "Bright Futures") }
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

    context "when a school appears in multiple bodies" do
      it "only includes the region code once" do
        FactoryBot.create(:region_award, appropriate_body_period: first_period, region: region_south, school: provisioning_school_2)

        expect(region_codes).to contain_exactly("R1", "R2")
      end
    end
  end

  describe "#has_multiple_ongoing_appropriate_body_periods?" do
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

    context "when the hub has a single ongoing period" do
      before { first_period }

      it { is_expected.not_to have_multiple_ongoing_appropriate_body_periods }
    end

    context "when the hub has more than one ongoing period" do
      before do
        first_period
        second_period
      end

      it { is_expected.to have_multiple_ongoing_appropriate_body_periods }
    end

    context "when the hub has ongoing and finished periods" do
      before do
        first_period
        inactive_second_period
      end

      it { is_expected.not_to have_multiple_ongoing_appropriate_body_periods }
    end

    context "when one ongoing period cannot be signed in to" do
      before do
        FactoryBot.create(:appropriate_body_period, :teaching_school_hub, :cannot_sign_in,
                          teaching_school_hub:,
                          provisioning_school: provisioning_school_1,
                          name: "First Body")
        second_period
      end

      it { is_expected.to have_multiple_ongoing_appropriate_body_periods }
    end
  end
end
