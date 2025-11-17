describe Migrators::Schedule do
  it_behaves_like "a migrator", :schedule, [:contract_period] do
    let(:schedule_identifiers) do
      %w[
        ecf-standard-september
        ecf-standard-january
        ecf-standard-april
        ecf-extended-september
        ecf-extended-january
        ecf-extended-april
        ecf-reduced-september
        ecf-reduced-january
        ecf-reduced-april
      ].cycle
    end

    def create_migration_resource
      cohort = FactoryBot.create(:migration_cohort, :with_sequential_start_year)
      identifier = schedule_identifiers.next
      FactoryBot.create(:migration_schedule, cohort:, type: "Finance::Schedule::ECF", schedule_identifier: identifier)
    end

    def create_resource(migration_resource)
      contract_period = ContractPeriod.find_or_create_by!(year: migration_resource.cohort.start_year) do |cp|
        cp.started_on = Date.new(migration_resource.cohort.start_year, 6, 1)
        cp.finished_on = Date.new(migration_resource.cohort.start_year + 1, 5, 31)
      end
      Schedule.find_or_create_by!(identifier: migration_resource.schedule_identifier, contract_period_year: contract_period.year)
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

      it "includes both Finance::Schedule::ECF and Finance::Schedule::Mentor type schedules" do
        cohort = FactoryBot.create(:migration_cohort, :with_sequential_start_year)

        ecf_schedule = FactoryBot.create(:migration_schedule, cohort:, type: "Finance::Schedule::ECF", schedule_identifier: "ecf-standard-september")
        mentor_schedule = FactoryBot.create(:migration_schedule, cohort:, type: "Finance::Schedule::Mentor", schedule_identifier: "ecf-replacement-september")

        schedules = described_class.schedules

        expect(schedules).to include(ecf_schedule)
        expect(schedules).to include(mentor_schedule)
      end
    end
  end
end
