module Migrators
  class Statement < Migrators::Base
    def self.record_count
      statements.count
    end

    def self.model
      :statement
    end

    def self.statements
      ::Migration::Statement.all
    end

    def self.dependencies
      %i[lead_provider registration_period active_lead_provider]
    end

    def self.reset!
      if Rails.application.config.enable_migration_testing
        ::Statement.connection.execute("TRUNCATE #{::Statement.table_name} RESTART IDENTITY CASCADE")
      end
    end

    def migrate!
      migrate(self.class.statements) do |ecf_statement|
        statement = ::Statement.find_or_initialize_by(api_id: ecf_statement.id)

        lead_provider_id = find_lead_provider_id!(ecf_id: ecf_statement.lead_provider.id)
        registration_period_id = ecf_statement.cohort.start_year

        statement.update!(
          active_lead_provider_id: find_active_lead_provider_id!(lead_provider_id:, registration_period_id:),
          month: Date::MONTHNAMES.find_index(ecf_statement.name.split[0]),
          year: ecf_statement.name.split[1],
          deadline_date: ecf_statement.deadline_date,
          payment_date: ecf_statement.payment_date,
          marked_as_paid_at: ecf_statement.marked_as_paid_at,
          output_fee: ecf_statement.output_fee,
          status: status(ecf_statement),
          created_at: ecf_statement.created_at,
          updated_at: ecf_statement.updated_at
        )
      end
    end

  private

    def status(ecf_statement)
      case ecf_statement.type
      when "Finance::Statement::ECF::Payable"
        :payable
      when "Finance::Statement::ECF::Paid"
        :paid
      else
        :open
      end
    end
  end
end
