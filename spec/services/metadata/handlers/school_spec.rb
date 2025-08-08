RSpec.describe Metadata::Handlers::School do
  let(:instance) { described_class.new(school) }
  let(:school) { FactoryBot.create(:school) }
  let(:school_partnership) { FactoryBot.create(:school_partnership, school:) }
  let!(:lead_provider) { school_partnership.lead_provider }
  let!(:contract_period) { school_partnership.contract_period }

  describe ".refresh_all_metadata!" do
    subject(:refresh_all_metadata) { described_class.refresh_all_metadata! }

    before { stub_const("Metadata::Handlers::School::BATCH_SIZE", 2) }

    it "enqueues jobs to refresh metadata for all eligible schools in batches" do
      schools = FactoryBot.create_list(:school, 2, :eligible)
      school_ids = ([school] + schools).map(&:id)

      expect(RefreshMetadataJob).to receive(:perform_later).with(
        object_type: School,
        object_ids: school_ids[0..1]
      )

      expect(RefreshMetadataJob).to receive(:perform_later).with(
        object_type: School,
        object_ids: school_ids[2..2]
      )

      refresh_all_metadata
    end
  end

  describe "#refresh_metadata!" do
    subject(:refresh_metadata) { instance.refresh_metadata! }

    describe "SchoolContractPeriod" do
      it "creates metadata for the school and contract period" do
        expect { refresh_metadata }.to change(Metadata::SchoolContractPeriod, :count).by(1)

        created_metadata = Metadata::SchoolContractPeriod.last

        expect(created_metadata).to have_attributes(
          school:,
          contract_period:,
          in_partnership: true,
          induction_programme_choice: "not_yet_known"
        )
      end

      it "creates metadata for all combinations of the school and contract periods" do
        FactoryBot.create_list(:contract_period, 3)

        expect { refresh_metadata }.to change(Metadata::SchoolContractPeriod, :count).by(ContractPeriod.count)
      end

      context "when metadata already exists for a school and contract period" do
        let!(:metadata) { FactoryBot.create(:school_contract_period_metadata, school:, contract_period:, in_partnership: true, induction_programme_choice: "not_yet_known") }

        it "does not create metadata" do
          expect { refresh_metadata }.not_to change(Metadata::SchoolContractPeriod, :count)
        end

        it "updates the metadata when the partnership changes" do
          Metadata::SchoolContractPeriod.bypass_update_restrictions { metadata.update!(in_partnership: false) }

          expect { refresh_metadata }.to change { metadata.reload.in_partnership }.from(false).to(true)
        end

        it "updates the metadata when the induction programme choice changes" do
          Metadata::SchoolContractPeriod.bypass_update_restrictions { metadata.update!(induction_programme_choice: "provider_led") }

          expect { refresh_metadata }.to change { metadata.reload.induction_programme_choice }.from("provider_led").to("not_yet_known")
        end

        it "does not update the metadata if no changes are made" do
          expect { refresh_metadata }.not_to(change { metadata.reload.attributes })
        end
      end
    end

    describe "SchoolLeadProviderContractPeriod" do
      it "creates metadata for the school, lead provider and contract period" do
        expect { refresh_metadata }.to change(Metadata::SchoolLeadProviderContractPeriod, :count).by(1)

        created_metadata = Metadata::SchoolLeadProviderContractPeriod.last

        expect(created_metadata).to have_attributes(
          school:,
          lead_provider:,
          contract_period:,
          expression_of_interest: false
        )
      end

      it "creates metadata for all combinations of the school, lead providers and contract periods" do
        FactoryBot.create_list(:contract_period, 3)
        FactoryBot.create_list(:lead_provider, 2)

        expect { refresh_metadata }.to change(Metadata::SchoolLeadProviderContractPeriod, :count).by(LeadProvider.count * ContractPeriod.count)
      end

      context "when metadata already exists for a school, lead provider and contract period" do
        let!(:metadata) { FactoryBot.create(:school_lead_provider_contract_period_metadata, school:, lead_provider:, contract_period:, expression_of_interest: false) }

        it "does not create metadata" do
          expect { refresh_metadata }.not_to change(Metadata::SchoolLeadProviderContractPeriod, :count)
        end

        it "updates the metadata when the partnership changes" do
          Metadata::SchoolLeadProviderContractPeriod.bypass_update_restrictions { metadata.update!(expression_of_interest: true) }

          expect { refresh_metadata }.to change { metadata.reload.expression_of_interest }.from(true).to(false)
        end

        it "does not update the metadata if no changes are made" do
          expect { refresh_metadata }.not_to(change { metadata.reload.attributes })
        end
      end
    end
  end
end
