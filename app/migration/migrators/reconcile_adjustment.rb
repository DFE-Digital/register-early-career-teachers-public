module Migrators
  class ReconcileAdjustment < Migrators::Base
    def self.record_count
      statements_with_adjustments.count
    end

    def self.model
      # this is really :statement_adjustment but if we use that it won't queue both
      :reconcile_adjustment
    end

    def self.statements_with_adjustments
      Migration::Statement.where.not(reconcile_amount: 0.0)
    end

    def self.dependencies
      %i[statement]
    end

    def self.reset!
      if Rails.application.config.enable_migration_testing
        ::Statement::Adjustment.connection.execute("TRUNCATE #{::Statement::Adjustment.table_name} RESTART IDENTITY CASCADE")
      end
    end

    def migrate!
      migrate(self.class.statements_with_adjustments) do |statement|
        migrate_one!(statement)
      end
    end

    def migrate_one!(statement_with_adjustment)
      statement_adjustment = ::Statement::Adjustment.find_or_initialize_by(ecf_id: statement_with_adjustment.id)

      statement_adjustment.statement = find_statement_by_api_id!(statement_with_adjustment.id)
      statement_adjustment.payment_type = "Reconcile amounts pre-adjustments feature"
      statement_adjustment.amount = statement_with_adjustment.reconcile_amount

      statement_adjustment.created_at = statement_with_adjustment.created_at
      statement_adjustment.updated_at = statement_with_adjustment.updated_at

      statement_adjustment.save!
      statement_adjustment
    end

    private

    def preload_caches
      cache_manager.cache_statements
    end
  end
end
