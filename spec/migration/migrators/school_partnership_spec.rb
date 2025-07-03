describe Migrators::SchoolPartnership do
  it_behaves_like "a migrator", :school_partnership, %i[lead_provider_delivery_partnership] do
    def create_migration_resource
      FactoryBot.create(:migration_partnership)
    end

    def create_resource(migration_resource)
      # creating dependencies resources
      lead_provider = FactoryBot.create(:lead_provider, name: migration_resource.lead_provider.name, ecf_id: migration_resource.lead_provider_id)
      delivery_partner = FactoryBot.create(:delivery_partner, name: migration_resource.delivery_partner.name, api_id: migration_resource.delivery_partner.id)
      contract_period = FactoryBot.create(:contract_period, year: migration_resource.cohort.start_year)

      active_lead_provider = FactoryBot.create(:active_lead_provider, lead_provider:, contract_period:)

      FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:, delivery_partner:)

      FactoryBot.create(:school, urn: migration_resource.school.urn)
    end

    def setup_failure_state
      # Record to be migrated with unmet dependencies in the destination db
      create_migration_resource
    end

    describe "#migrate!" do
      it "sets the created record attributes correctly" do
        instance.migrate!

        described_class.partnerships.find_each do |partnership|
          school_partnership = SchoolPartnership.find_by!(api_id: partnership.id)

          lead_provider = school_partnership.lead_provider_delivery_partnership.active_lead_provider.lead_provider
          year = school_partnership.lead_provider_delivery_partnership.active_lead_provider.contract_period_id
          delivery_partner = school_partnership.lead_provider_delivery_partnership.delivery_partner
          school = school_partnership.school

          expect(lead_provider.ecf_id).to eq partnership.lead_provider_id
          expect(delivery_partner.api_id).to eq partnership.delivery_partner_id
          expect(year).to eq partnership.cohort.start_year
          expect(school.urn.to_s).to eq partnership.school.urn
        end
      end
    end
  end
end
