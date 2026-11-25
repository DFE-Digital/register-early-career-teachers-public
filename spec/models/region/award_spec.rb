RSpec.describe Region::Award, type: :model do
  let(:appropriate_body_period) { FactoryBot.create(:appropriate_body_period, :teaching_school_hub) }
  let(:other_appropriate_body_period) { FactoryBot.create(:appropriate_body_period, :teaching_school_hub) }
  let(:region) { FactoryBot.create(:region) }
  let(:lead_school) { FactoryBot.create(:school) }
  let(:other_lead_school) { FactoryBot.create(:school) }

  describe "associations" do
    it { is_expected.to belong_to(:appropriate_body_period) }
    it { is_expected.to belong_to(:lead_school).class_name("School") }
    it { is_expected.to belong_to(:region) }
  end

  describe "scopes" do
    describe ".active" do
      it "returns lead schools still holding a regional award" do
        active = FactoryBot.create(:region_award)
        FactoryBot.create(:region_award, :deactivated)

        expect(described_class.active).to contain_exactly(active)
      end
    end
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:appropriate_body_period) }
    it { is_expected.to validate_presence_of(:lead_school) }
    it { is_expected.to validate_presence_of(:region) }

    describe "lead school regional awards" do
      it "cannot award a region to multiple schools at once" do
        FactoryBot.create(:region_award, appropriate_body_period:, lead_school:, region:)

        other_award = FactoryBot.build(:region_award,
                                       appropriate_body_period: other_appropriate_body_period,
                                       lead_school: other_lead_school,
                                       region:)

        expect(other_award).not_to be_valid
        expect(other_award).to have_error(:region_id, "is already awarded to #{lead_school.name}")
      end

      it "allows the school to be linked to more than one active hub (legislative loophole to be closed)" do
        FactoryBot.create(:region_award, appropriate_body_period:, lead_school:, region:)

        other_award = FactoryBot.build(:region_award,
                                       appropriate_body_period: other_appropriate_body_period,
                                       lead_school:,
                                       region:)

        expect(other_award).to be_valid
        expect { other_award.save! }.not_to raise_error
      end

      it "cannot award a region twice within one appropriate body" do
        FactoryBot.create(:region_award, appropriate_body_period:, lead_school:, region:)

        other_award = FactoryBot.build(:region_award,
                                       appropriate_body_period:,
                                       lead_school: other_lead_school,
                                       region:)

        expect(other_award).not_to be_valid
        expect(other_award).to have_error(:region_id, "is already linked to this appropriate body")
      end

      it "cannot reactivate a closed award while the region is led by another school" do
        deactivated = FactoryBot.create(:region_award, :deactivated, appropriate_body_period:, lead_school:, region:)
        FactoryBot.create(:region_award,
                          appropriate_body_period: other_appropriate_body_period,
                          lead_school: other_lead_school,
                          region:)

        expect { deactivated.update!(deactivated_at: nil) }
          .to raise_error(ActiveRecord::RecordInvalid, /is already awarded to/)
      end

      it "allows a lead school to return to an appropriate body for a region it held before" do
        FactoryBot.create(:region_award, :deactivated, appropriate_body_period:, lead_school:, region:)

        rejoin = FactoryBot.build(:region_award, appropriate_body_period:, lead_school:, region:)

        expect(rejoin).to be_valid
        expect { rejoin.save! }.not_to raise_error
      end

      it "keeps a region's history when it moves between appropriate bodies" do
        FactoryBot.create(:region_award, :deactivated, appropriate_body_period:, lead_school:, region:)
        current = FactoryBot.create(:region_award,
                                    appropriate_body_period: other_appropriate_body_period,
                                    lead_school: other_lead_school,
                                    region:)

        expect(described_class.where(region:).count).to be(2)
        expect(described_class.active).to contain_exactly(current)
      end

      it "keeps a closed award editable while the region is held by another body" do
        closed = FactoryBot.create(:region_award, :deactivated, appropriate_body_period:, lead_school:, region:)
        FactoryBot.create(:region_award,
                          appropriate_body_period: other_appropriate_body_period,
                          lead_school: other_lead_school,
                          region:)

        expect { closed.update!(deactivation_reason: "corrected reason") }.not_to raise_error
      end

      it "allows a lead school to hold several regions at once" do
        award = FactoryBot.create(:region_award, lead_school:, region:)
        other_region = FactoryBot.create(:region)
        FactoryBot.create(:region_award,
                          appropriate_body_period: award.appropriate_body_period,
                          lead_school:,
                          region: other_region)

        expect(lead_school.awarded_regions).to contain_exactly(region, other_region)
      end
    end
  end

  describe "#active?" do
    context "when the award has not been deactivated" do
      subject(:award) { FactoryBot.build(:region_award) }

      it { is_expected.to be_active }
    end

    context "when the award has been deactivated" do
      subject(:award) { FactoryBot.build(:region_award, :deactivated) }

      it { is_expected.not_to be_active }
    end
  end

  describe "#lead_school_is_the_provisioner?" do
    subject(:award) do
      FactoryBot.build(:region_award, appropriate_body_period:, lead_school:)
    end

    let(:appropriate_body_period) { FactoryBot.create(:appropriate_body_period, :teaching_school_hub) }

    context "when school is responsible for appropriate body duties" do
      let(:lead_school) { appropriate_body_period.provisioning_school }

      it { is_expected.to be_lead_school_is_the_provisioner }
    end

    context "when school is not responsible for appropriate body duties" do
      let(:lead_school) { FactoryBot.create(:school) }

      it { is_expected.not_to be_lead_school_is_the_provisioner }
    end
  end

  context "when a region is already awarded" do
    before do
      FactoryBot.create(:region_award, appropriate_body_period:, lead_school:, region:)
    end

    let(:other_award) do
      FactoryBot.build(:region_award,
                       appropriate_body_period: other_appropriate_body_period,
                       lead_school: other_lead_school,
                       region:)
    end

    it "#other_awards_for_region" do
      expect(other_award.other_awards_for_region).to contain_exactly(region.active_awards.sole)
    end

    it "#other_lead_schools" do
      expect(other_award.other_lead_schools).to contain_exactly(lead_school)
    end
  end
end
