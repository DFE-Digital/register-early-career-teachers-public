module Statements
  class Update
    attr_reader :statement, :author, :params

    def initialize(author:, statement:, params:)
      @author = author
      @statement = statement
      @params = params
    end

    def call
      statement.assign_attributes(params)
      modifications = statement.changes

      ActiveRecord::Base.transaction do
        statement.save!
        Events::Record.record_statement_updated_event!(author:, statement:, modifications:)
      end

      statement
    end
  end
end
