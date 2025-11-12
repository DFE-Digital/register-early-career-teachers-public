describe Migrators::Milestone do
  it_behaves_like "a migrator", :milestone, [:schedule] do
    def create_migration_resource
      cohort = FactoryBot.create(:migration_cohort, :with_sequential_start_year)
      schedule = FactoryBot.create(:migration_schedule, cohort:, type: "Finance::Schedule::ECF")
      FactoryBot.create(:migration_milestone, schedule:)
    end

    def create_resource(migration_resource)
      contract_period = ContractPeriod.find_or_create_by!(year: migration_resource.schedule.cohort.start_year) do |cp|
        cp.started_on = Date.new(migration_resource.schedule.cohort.start_year, 6, 1)
        cp.finished_on = Date.new(migration_resource.schedule.cohort.start_year + 1, 5, 31)
      end
      Schedule.find_or_create_by!(identifier: migration_resource.schedule.schedule_identifier, contract_period_year: contract_period.year)
    end

    def setup_failure_state
      # Milestone with a schedule that doesn't exist in RECT
      cohort = FactoryBot.create(:migration_cohort, start_year: 2010)
      schedule = FactoryBot.create(:migration_schedule, cohort:, type: "Finance::Schedule::ECF")
      FactoryBot.create(:migration_milestone, schedule:)
    end

    describe "#migrate!" do
      it "sets the created milestone attributes correctly" do
        instance.migrate!

        milestone = Milestone.find_by(
          schedule_id: Schedule.find_by(
            identifier: migration_resource1.schedule.schedule_identifier,
            contract_period_year: migration_resource1.schedule.cohort.start_year
          ).id,
          declaration_type: migration_resource1.declaration_type
        )

        expect(milestone).to have_attributes(
          migration_resource1.attributes.slice("start_date", "milestone_date", "created_at", "updated_at")
        )
        expect(milestone.declaration_type).to eq(migration_resource1.declaration_type)
      end
    end
  end
end
