describe Migrators::ContractPeriod do
  it_behaves_like "a migrator", :contract_period, [] do
    def create_migration_resource
      FactoryBot.create(:migration_cohort, :with_sequential_start_year)
    end

    def create_resource(migration_resource)
      FactoryBot.create(:contract_period, year: migration_resource.start_year)
    end

    def setup_failure_state
      # Record to be migrated with invalid start year
      FactoryBot.create(:migration_cohort, start_year: 2010)
    end

    describe "#migrate!" do
      it "sets the created contract_period attributes correctly" do
        instance.migrate!

        contract_period = ContractPeriod.find_by(year: migration_resource1.start_year)
        expect(contract_period).to have_attributes(migration_resource1.attributes.slice("created_at", "updated_at"))
        expect(contract_period.id).to eq(migration_resource1.start_year)
        expect(contract_period.started_on.to_date).to eq(migration_resource1.registration_start_date.to_date)
        expect(contract_period.finished_on).to eq(contract_period.started_on.next_year.prev_day)
        expect(contract_period.enabled).to be(true)
      end
    end
  end
end
