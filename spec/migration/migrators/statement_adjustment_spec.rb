describe Migrators::StatementAdjustment do
  it_behaves_like "a migrator", :statement_adjustment, %i[statement] do
    def create_migration_resource
      FactoryBot.create(:migration_finance_adjustment)
    end

    def create_resource(migration_resource)
      # creating dependencies resources

      ecf_lp = migration_resource.statement.lead_provider
      ecf_cohort = migration_resource.statement.cohort

      lead_provider = FactoryBot.create(:lead_provider, name: ecf_lp.name, api_id: ecf_lp.id)
      registration_period = FactoryBot.create(:registration_period, year: ecf_cohort.start_year)
      active_lead_provider = FactoryBot.create(:active_lead_provider, lead_provider:, registration_period:)
      FactoryBot.create(:statement, api_id: migration_resource.statement_id, lead_provider:, registration_period:, active_lead_provider:)
    end

    def setup_failure_state
      # add a resource to migrate but don't create migrated dependencies
      create_migration_resource
    end

    describe "#migrate!" do
      it "sets the created statement adjustment attributes correctly" do
        instance.migrate!

        Migration::FinanceAdjustment.find_each do |finance_adjustment|
          adjustment = ::Statement::Adjustment.find_by!(api_id: finance_adjustment.id)
          adjustment.statement

          expect(adjustment.api_id).to eq finance_adjustment.id
          expect(adjustment.payment_type).to eq finance_adjustment.payment_type
          expect(adjustment.amount).to eq finance_adjustment.amount
          expect(adjustment.created_at).to eq finance_adjustment.created_at
          expect(adjustment.updated_at).to eq finance_adjustment.updated_at
        end
      end
    end
  end
end
