module Statements
  class Create
    attr_reader :statement, :author

    def initialize(author:, params:)
      @author = author
      @statement = Statement.new(params)
      @statement.fee_type = FeeTypeForMonth.new(month: @statement.month).call
    end

    def call
      ActiveRecord::Base.transaction do
        statement.save!
        Events::Record.record_statement_created_event!(author:, statement:)
      end

      statement
    end
  end
end
