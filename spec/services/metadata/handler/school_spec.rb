RSpec.describe Metadata::Handler::School do
  let(:instance) { described_class.new }
  let(:school) { FactoryBot.create(:school) }
  let!(:lead_provider) { FactoryBot.create(:lead_provider) }
  let!(:contract_period) { FactoryBot.create(:contract_period) }

  describe "#create_metadata!" do
    subject(:create_metadata) { instance.create_metadata!(school) }

    it "creates metadata for all lead provider and contract period combinations" do
      created_metadata = nil
      expect { created_metadata = create_metadata.first }.to change(Metadata::SchoolLeadProviderContractPeriod, :count).by(1)

      expect(created_metadata).to have_attributes(
        school:,
        lead_provider:,
        contract_period:,
        in_partnership: false,
        expression_of_interest: false,
        induction_programme_choice: "not_yet_known"
      )
    end

    it "does not create metadata if it already exists for the same lead provider and contract period" do
      FactoryBot.create(:school_lead_provider_contract_period_metadata, school:, lead_provider:, contract_period:)
      expect { create_metadata }.not_to change(Metadata::SchoolLeadProviderContractPeriod, :count)
    end
  end

  describe "#update_metadata!" do
    subject(:update_metadata) { instance.update_metadata!(school) }

    let!(:metadata) { instance.create_metadata!(school).first }

    context "when the partnership state has changed" do
      before { Metadata::SchoolLeadProviderContractPeriod.bypass_update_restrictions { metadata.update!(in_partnership: true) } }

      it { expect { update_metadata }.to change { metadata.reload.in_partnership }.from(true).to(false) }
    end

    context "when the expression of interest state has changed" do
      before { Metadata::SchoolLeadProviderContractPeriod.bypass_update_restrictions { metadata.update!(expression_of_interest: true) } }

      it { expect { update_metadata }.to change { metadata.reload.expression_of_interest }.from(true).to(false) }
    end

    context "when the induction programme choice has changed" do
      before { Metadata::SchoolLeadProviderContractPeriod.bypass_update_restrictions { metadata.update!(induction_programme_choice: "provider_led") } }

      it { expect { update_metadata }.to change { metadata.reload.induction_programme_choice }.from("provider_led").to("not_yet_known") }
    end

    context "when no changes are made" do
      it { expect { update_metadata }.not_to(change { metadata.reload.attributes }) }
    end
  end
end
