RSpec.describe SchoolPartnerships::Create, type: :model do
  let(:service) do
    described_class.new(
      contract_period_year:,
      school_api_id:,
      lead_provider_id:,
      delivery_partner_api_id:
    )
  end

  let(:contract_period) { FactoryBot.create(:contract_period) }
  let(:contract_period_year) { contract_period.year }

  let(:school) { FactoryBot.create(:school, :eligible) }
  let(:school_api_id) { school.api_id }

  let(:lead_provider) { FactoryBot.create(:lead_provider) }
  let(:lead_provider_id) { lead_provider.id }

  let(:delivery_partner) { FactoryBot.create(:delivery_partner) }
  let(:delivery_partner_api_id) { delivery_partner.api_id }

  let!(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:, contract_period:) }
  let!(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:, delivery_partner:) }

  let!(:metadata) { FactoryBot.create(:school_contract_period_metadata, contract_period:, school:, induction_programme_choice: :provider_led) }

  describe "validations" do
    subject { service }

    it { is_expected.to be_valid }

    it { is_expected.to validate_presence_of(:contract_period_year).with_message("Enter a '#/cohort'.") }
    it { is_expected.to validate_presence_of(:school_api_id).with_message("Enter a '#/school_id'.") }
    it { is_expected.to validate_presence_of(:lead_provider_id).with_message("Enter a '#/lead_provider_id'.") }
    it { is_expected.to validate_presence_of(:delivery_partner_api_id).with_message("Enter a '#/delivery_partner_id'.") }

    context "when the contract period year does not exist" do
      let(:contract_period_year) { contract_period.year - 1 }

      it "is invalid" do
        expect(service).to be_invalid
        expect(service.errors[:contract_period_year]).to include("The '#/cohort' you have entered is invalid. Check cohort details and try again.")
      end
    end

    context "when the contract period year is not enabled" do
      before { contract_period.update!(enabled: false) }

      it "is invalid" do
        expect(service).to be_invalid
        expect(service.errors[:contract_period_year]).to include("You cannot create this partnership until the cohort has started.")
      end
    end

    context "when the lead provider does not exist" do
      let(:lead_provider_id) { -1 }

      it "is invalid" do
        expect(service).to be_invalid
        expect(service.errors[:lead_provider_id]).to include("Enter a '#/lead_provider_id'.")
      end
    end

    context "when the school does not exist" do
      let(:school_api_id) { SecureRandom.uuid }

      it "is invalid" do
        expect(service).to be_invalid
        expect(service.errors[:school_api_id]).to include("The '#/school_id' you have entered is invalid. Check school details and try again. Contact the DfE for support if you are unable to find the '#/school_id'.")
      end
    end

    context "when the school is CIP only" do
      let(:school) { FactoryBot.create(:school, :cip_only) }

      it "is invalid" do
        expect(service).to be_invalid
        expect(service.errors[:school_api_id]).to include("The school you have entered has not registered to deliver DfE-funded training. Contact the school for more information.")
      end
    end

    context "when the school is not eligible" do
      let(:school) { FactoryBot.create(:school, :ineligible) }

      it "is invalid" do
        expect(service).to be_invalid
        expect(service.errors[:school_api_id]).to include("The school you have entered is currently ineligible for DfE funding. Contact the school for more information.")
      end
    end

    context "when a school partnership already exists for the lead provider and contract period" do
      before { FactoryBot.create(:school_partnership, school:, lead_provider_delivery_partnership:) }

      it "is invalid" do
        expect(service).to be_invalid
        expect(service.errors[:school_api_id]).to include("You are already in a confirmed partnership with this school for the entered cohort.")
      end
    end

    context "when a school partnership already exists for the lead provider and a different contract period" do
      before do
        contract_period = FactoryBot.create(:contract_period, year: contract_period_year + 1)
        active_lead_provider = FactoryBot.create(:active_lead_provider, lead_provider:, contract_period:)
        lead_provider_delivery_partnership = FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:, delivery_partner:)

        FactoryBot.create(:school_partnership, school:, lead_provider_delivery_partnership:)
      end

      it { is_expected.to be_valid }
    end

    context "when a school partnership already exists for the the contract period and a different lead provider" do
      before do
        lead_provider = FactoryBot.create(:lead_provider)
        active_lead_provider = FactoryBot.create(:active_lead_provider, lead_provider:, contract_period:)
        lead_provider_delivery_partnership = FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:, delivery_partner:)

        FactoryBot.create(:school_partnership, school:, lead_provider_delivery_partnership:)
      end

      it { is_expected.to be_valid }
    end

    context "when the delivery partner does not exist" do
      let(:delivery_partner_api_id) { SecureRandom.uuid }

      it "is invalid" do
        expect(service).to be_invalid
        expect(service.errors[:delivery_partner_api_id]).to include("The '#/delivery_partner_id' you have entered is invalid. Check delivery partner details and try again.")
      end
    end

    context "when a lead provider delivery partnership does not exist" do
      let(:lead_provider_delivery_partnership) { nil }

      it "is invalid" do
        expect(service).to be_invalid
        expect(service.errors[:delivery_partner_api_id]).to include("The entered delivery partner is not recognised to be working in partnership with you for the given cohort. Contact the DfE for more information.")
      end
    end

    context "when the induction programme choice is school_led" do
      before { Metadata::SchoolContractPeriod.bypass_update_restrictions { metadata.update!(induction_programme_choice: :school_led) } }

      it "is invalid" do
        expect(service).to be_invalid
        expect(service.errors[:induction_programme_choice]).to include("The school you have entered has not yet confirmed they will deliver DfE-funded training. Contact the school for more information.")
      end
    end

    context "when the induction programme choice is not_yet_known" do
      before { Metadata::SchoolContractPeriod.bypass_update_restrictions { metadata.update!(induction_programme_choice: :not_yet_known) } }

      it { is_expected.to be_valid }
    end
  end

  describe "#create" do
    subject(:create_school_partnership) { service.create }

    it "creates a school partnership" do
      created_school_partnership = nil

      expect { created_school_partnership = create_school_partnership }.to change(SchoolPartnership, :count).by(1)

      expect(created_school_partnership).to have_attributes(school:, lead_provider_delivery_partnership:)
    end

    it "records a school partnership created event" do
      allow(Events::Record).to receive(:record_school_partnership_created_event!).once.and_call_original

      school_partnership = create_school_partnership

      expect(Events::Record).to have_received(:record_school_partnership_created_event!).once.with(
        hash_including(
          {
            school_partnership:,
            author: kind_of(Events::LeadProviderAuthor),
          }
        )
      )
    end

    context "when invalid" do
      let(:school_api_id) { SecureRandom.uuid }

      it { is_expected.to be(false) }
      it { expect { create_school_partnership }.not_to change(SchoolPartnership, :count) }
    end
  end
end
