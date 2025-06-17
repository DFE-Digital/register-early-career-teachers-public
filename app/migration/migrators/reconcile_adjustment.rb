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
        statement_adjustment = ::Statement::Adjustment.find_or_initialize_by(api_id: statement.id)

        statement_adjustment.statement = ::Statement.find_by!(api_id: statement.id)
        statement_adjustment.payment_type = "Reconcile amounts pre-adjustments feature"
        statement_adjustment.amount = statement.reconcile_amount

        statement_adjustment.created_at = statement.created_at
        statement_adjustment.updated_at = statement.updated_at

        statement_adjustment.save!
      end
    end
  end
end
