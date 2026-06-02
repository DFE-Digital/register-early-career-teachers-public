module Statements
  class Destroy
    class DeletionError < StandardError; end

    attr_reader :statement, :author

    def initialize(author:, statement:)
      @author = author
      @statement = statement
    end

    def call
      raise DeletionError, "Cannot delete a statement with declarations" if statement.referenced_by_declarations?

      active_lead_provider = statement.active_lead_provider
      lead_provider = active_lead_provider.lead_provider
      heading = "Statement deleted: #{Statements::Period.for(statement)} #{statement.fee_type} for #{lead_provider.name}"
      modifications = statement.attributes.transform_values { |value| [value, nil] }

      ActiveRecord::Base.transaction do
        statement.destroy!
        Events::Record.record_statement_deleted_event!(
          author:,
          active_lead_provider:,
          modifications:,
          heading:
        )
      end

      true
    end
  end
end
