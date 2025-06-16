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
        statement_adjustment = ::Statement::Adjustment.find_or_initialize_by(api_id: adjustment.id)

        statement_adjustment.statement = ::Statement.find_by!(api_id: adjustment.statement_id)
        statement_adjustment.payment_type = adjustment.payment_type
        statement_adjustment.amount = adjustment.amount
        statement_adjustment.created_at = adjustment.created_at
        statement_adjustment.updated_at = adjustment.updated_at

        statement_adjustment.save!
      end
    end
  end
end
