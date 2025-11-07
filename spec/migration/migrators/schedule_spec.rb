describe Migrators::Schedule do
  it_behaves_like "a migrator", :schedule, [:contract_period] do
    def create_migration_resource
      cohort = FactoryBot.create(:migration_cohort, :with_sequential_start_year)
      FactoryBot.create(:migration_schedule, cohort:, type: "Finance::Schedule::ECF")
    end

    def create_resource(migration_resource)
      contract_period = FactoryBot.create(:contract_period, year: migration_resource.cohort.start_year)
      FactoryBot.create(:schedule, identifier: migration_resource.schedule_identifier, contract_period_year: contract_period.year)
    end

    def setup_failure_state
      # Schedule with a non-existent contract period
      cohort = FactoryBot.create(:migration_cohort, start_year: 2010)
      FactoryBot.create(:migration_schedule, cohort:, type: "Finance::Schedule::ECF")
    end

    describe "#migrate!" do
      it "sets the created schedule attributes correctly" do
        instance.migrate!

        schedule = Schedule.find_by(
          identifier: migration_resource1.schedule_identifier,
          contract_period_year: migration_resource1.cohort.start_year
        )

        expect(schedule).to have_attributes(
          migration_resource1.attributes.slice("created_at", "updated_at")
        )
        expect(schedule.identifier).to eq(migration_resource1.schedule_identifier)
        expect(schedule.contract_period_year).to eq(migration_resource1.cohort.start_year)
      end

      it "only migrates Finance::Schedule::ECF type schedules" do
        # Create a non-ECF schedule (e.g., Mentor schedule)
        cohort = FactoryBot.create(:migration_cohort, :with_sequential_start_year)
        FactoryBot.create(:migration_schedule, cohort:, type: "Finance::Schedule::Mentor")

        expect { instance.migrate! }.not_to change(Schedule, :count)
      end
    end
  end
end
