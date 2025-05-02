RSpec.describe API::SchoolPartnerships::Create, type: :model do
  let(:service) do
    described_class.new(
      registration_year:,
      school_ecf_id:,
      lead_provider_ecf_id:,
      delivery_partner_ecf_id:
    )
  end

  let(:registration_period) { create(:registration_period) }
  let(:registration_year) { registration_period.year }

  let(:gias_school) { create(:gias_school, :eligible_for_fip, :eligible_type) }
  let(:school) { create(:school, urn: gias_school.urn, gias_school: nil) }
  let(:school_ecf_id) { school.ecf_id }

  let(:lead_provider) { create(:lead_provider) }
  let(:lead_provider_ecf_id) { lead_provider.ecf_id }

  let(:delivery_partner) { create(:delivery_partner) }
  let(:delivery_partner_ecf_id) { delivery_partner.ecf_id }

  let!(:lead_provider_active_period) { create(:lead_provider_active_period, lead_provider:, registration_period:) }
  let!(:lead_provider_delivery_partnership) { create(:lead_provider_delivery_partnership, lead_provider_active_period:, delivery_partner:) }

  let(:ect_at_school_period) { create(:ect_at_school_period, school:, started_on: 1.year.ago, finished_on: 1.week.ago) }
  let!(:fip_participant) { create(:training_period, ect_at_school_period:, started_on: 2.months.ago, finished_on: 1.month.ago) }

  describe "validations" do
    subject { service }

    it { is_expected.to be_valid }

    it { is_expected.to validate_presence_of(:registration_year) }
    it { is_expected.to validate_presence_of(:school_ecf_id) }
    it { is_expected.to validate_presence_of(:lead_provider_ecf_id) }
    it { is_expected.to validate_presence_of(:delivery_partner_ecf_id) }

    context "when the registration year does not exist" do
      let(:registration_year) { registration_period.year - 1 }

      it "is invalid" do
        expect(service).to be_invalid
        expect(service.errors[:registration_year]).to include("Registration year does not exist")
      end
    end

    context "when the lead provider does not exist" do
      let(:lead_provider_ecf_id) { SecureRandom.uuid }

      it "is invalid" do
        expect(service).to be_invalid
        expect(service.errors[:lead_provider_ecf_id]).to include("Lead provider does not exist")
      end
    end

    context "when the school does not exist" do
      let(:school_ecf_id) { SecureRandom.uuid }

      it "is invalid" do
        expect(service).to be_invalid
        expect(service.errors[:school_ecf_id]).to include("School does not exist")
      end
    end

    context "when the school is CIP only" do
      let(:gias_school) { create(:gias_school, :cip_only) }

      it "is invalid" do
        expect(service).to be_invalid
        expect(service.errors[:school_ecf_id]).to include("School is CIP only")
      end
    end

    context "when the school is not eligible" do
      let(:gias_school) { create(:gias_school, :not_eligible_type) }

      it "is invalid" do
        expect(service).to be_invalid
        expect(service.errors[:school_ecf_id]).to include("School is not eligible")
      end
    end

    context "when the school partnership already exists" do
      before { create(:school_partnership, school:, lead_provider_delivery_partnership:) }

      it "is invalid" do
        expect(service).to be_invalid
        expect(service.errors[:school_ecf_id]).to include("School partnership already exists for the lead provider, delivery partner and registration year")
      end
    end

    context "when a school training period does not exist" do
      let(:other_school) { create(:school) }

      before { ect_at_school_period.update!(school: other_school) }

      it "is invalid" do
        expect(service).to be_invalid
        expect(service.errors[:school_ecf_id]).to include("School does not have any FIP participants")
      end
    end

    context "when a mentor at school period exists" do
      let(:mentor_at_school_period) { create(:mentor_at_school_period, school:, started_on: 1.year.ago, finished_on: 1.week.ago) }
      let!(:fip_participant) { create(:training_period, :for_mentor, mentor_at_school_period:, started_on: 2.months.ago, finished_on: 1.month.ago) }

      it { is_expected.to be_valid }
    end

    context "when the delivery partner does not exist" do
      let(:delivery_partner_ecf_id) { SecureRandom.uuid }

      it "is invalid" do
        expect(service).to be_invalid
        expect(service.errors[:delivery_partner_ecf_id]).to include("Delivery partner does not exist")
      end
    end

    context "when a lead provider delivery partnership does not exist" do
      let(:lead_provider_delivery_partnership) { nil }

      it "is invalid" do
        expect(service).to be_invalid
        expect(service.errors[:delivery_partner_ecf_id]).to include("Lead provider and delivery partner do not have a partnership")
      end
    end
  end

  describe "#create" do
    subject(:create_school_partnership) { service.create }

    it "creates a school partnership" do
      created_school_partnership = nil

      expect { created_school_partnership = create_school_partnership }.to change(SchoolPartnership, :count).by(1)

      expect(created_school_partnership).to have_attributes(school:, lead_provider_delivery_partnership:)
    end

    it "accepts expressions of interest for the lead provider active period providing the school is consistent" do
      ect_at_school_period = create(:ect_at_school_period, school:, started_on: 1.year.ago, finished_on: 1.week.ago)
      expression_of_interest = create(:training_period,
                                      school_partnership: nil,
                                      expression_of_interest: lead_provider_active_period,
                                      ect_at_school_period:,
                                      started_on: 2.months.ago,
                                      finished_on: 1.month.ago)
      created_school_partnership = create_school_partnership

      expect(expression_of_interest.reload.school_partnership).to eq(created_school_partnership)
    end

    it "ignores expressions of interest for the lead provider active period if the school is different" do
      ect_at_school_period = create(:ect_at_school_period, started_on: 1.year.ago, finished_on: 1.week.ago)
      expression_of_interest = create(:training_period,
                                      school_partnership: nil,
                                      expression_of_interest: lead_provider_active_period,
                                      ect_at_school_period:,
                                      started_on: 2.months.ago,
                                      finished_on: 1.month.ago)

      expect { create_school_partnership }.not_to(change { expression_of_interest.reload.school_partnership })
    end

    it "ignores expressions of interest for other lead provider active periods" do
      other_lead_provider_active_period = create(:lead_provider_active_period, registration_period:)
      ect_at_school_period = create(:ect_at_school_period, school:, started_on: 1.year.ago, finished_on: 1.week.ago)
      expression_of_interest = create(:training_period,
                                      school_partnership: nil,
                                      expression_of_interest: other_lead_provider_active_period,
                                      ect_at_school_period:,
                                      started_on: 2.months.ago,
                                      finished_on: 1.month.ago)

      expect { create_school_partnership }.not_to(change { expression_of_interest.reload.school_partnership })
    end

    context "when invalid" do
      let(:school_ecf_id) { SecureRandom.uuid }

      it { is_expected.to be(false) }
      it { expect { create_school_partnership }.not_to change(SchoolPartnership, :count) }
    end
  end
end
