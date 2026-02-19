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
      %i[lead_provider contract_period active_lead_provider contract]
    end

    def self.reset!
      if Rails.application.config.enable_migration_testing
        ::Statement.connection.execute("TRUNCATE #{::Statement.table_name} RESTART IDENTITY CASCADE")
      end
    end

    def migrate!
      migrate(self.class.statements) do |ecf_statement|
        migrate_one!(ecf_statement)
      end
    end

    def migrate_one!(ecf_statement)
      statement = ::Statement.find_or_initialize_by(api_id: ecf_statement.id)

      lead_provider_id = find_lead_provider_id!(ecf_id: ecf_statement.lead_provider.id)
      contract_period_year = ecf_statement.cohort.start_year
      active_lead_provider_id = find_active_lead_provider_id!(lead_provider_id:, contract_period_year:)

      statement.update!(
        active_lead_provider_id:,
        contract_id: find_contract_id!(active_lead_provider_id, ecf_statement.contract_version, ecf_statement.sanitized_mentor_contract_version),
        month: Date::MONTHNAMES.find_index(ecf_statement.name.split[0]),
        year: ecf_statement.name.split[1],
        deadline_date: ecf_statement.deadline_date,
        payment_date: ecf_statement.payment_date,
        marked_as_paid_at: ecf_statement.marked_as_paid_at,
        fee_type: fee_type(ecf_statement),
        status: status(ecf_statement),
        created_at: ecf_statement.created_at,
        updated_at: ecf_statement.updated_at
      )

      statement
    end

  private

    def find_contract_id!(active_lead_provider_id, ecf_contract_version, ecf_mentor_contract_version)
      ::Contract.where(active_lead_provider_id:, ecf_contract_version:, ecf_mentor_contract_version:).pick(:id) ||
        raise(ActiveRecord::RecordNotFound, "Unable to find contract for active_lead_provider_id: #{active_lead_provider_id}, ecf_contract_version: #{ecf_contract_version}, ecf_mentor_contract_version: #{ecf_mentor_contract_version}")
    end

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

    def fee_type(ecf_statement)
      ecf_statement.output_fee ? "output" : "service"
    end
  end
end
