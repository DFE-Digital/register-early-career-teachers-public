module Migrators
  class StatementAdjustment < Migrators::Base
    def self.record_count
      statement_adjustments.count
    end

    def self.model
      :statement_adjustment
    end

    def self.statement_adjustments
      Migration::FinanceAdjustment.all
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
      migrate(self.class.statement_adjustments) do |adjustment|
        migrate_one!(adjustment)
      end
    end

    def migrate_one!(ecf_adjustment)
      statement_adjustment = ::Statement::Adjustment.find_or_initialize_by(ecf_id: ecf_adjustment.id)

      statement_adjustment.statement = find_statement_by_api_id!(ecf_adjustment.statement_id)
      statement_adjustment.payment_type = ecf_adjustment.payment_type
      statement_adjustment.amount = ecf_adjustment.amount
      statement_adjustment.created_at = ecf_adjustment.created_at
      statement_adjustment.updated_at = ecf_adjustment.updated_at

      statement_adjustment.save!
      statement_adjustment
    end

  private

    def preload_caches
      cache_manager.cache_statements
    end
  end
end
