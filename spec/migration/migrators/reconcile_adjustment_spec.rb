describe Migrators::ReconcileAdjustment do
  it_behaves_like "a migrator", :reconcile_adjustment, %i[statement] do
    def create_migration_resource
      create(:migration_statement, reconcile_amount: 100.77)
    end

    def create_resource(migration_resource)
      # creating dependencies resources

      ecf_lp = migration_resource.lead_provider
      ecf_cohort = migration_resource.cohort

      lead_provider = create(:lead_provider, name: ecf_lp.name, ecf_id: ecf_lp.id)
      contract_period = create(:contract_period, year: ecf_cohort.start_year)
      active_lead_provider = create(:active_lead_provider, lead_provider:, contract_period:)
      create(:statement, api_id: migration_resource.id, lead_provider:, contract_period:, active_lead_provider:)
    end

    def setup_failure_state
      # add a resource to migrate but don't create migrated dependencies
      create_migration_resource
    end

    describe "#migrate!" do
      it "sets the created statement adjustment attributes correctly" do
        instance.migrate!

        described_class.statements_with_adjustments.find_each do |statement|
          adjustment = ::Statement::Adjustment.find_by!(api_id: statement.id)

          expect(adjustment.api_id).to eq statement.id
          expect(adjustment.payment_type).to eq "Reconcile amounts pre-adjustments feature"
          expect(adjustment.amount).to eq statement.reconcile_amount
          expect(adjustment.created_at).to eq statement.created_at
          expect(adjustment.updated_at).to eq statement.updated_at
        end
      end
    end
  end
end
