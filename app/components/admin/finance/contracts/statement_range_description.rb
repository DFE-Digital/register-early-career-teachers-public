class Admin::Finance::Contracts::StatementRangeDescription < ApplicationComponent
  def initialize(first_statement:, last_statement:)
    @first_statement = first_statement
    @last_statement = last_statement
  end

private

  def statement_range_description
    return "No statements" if @first_statement.nil?
    return description(@first_statement) if @first_statement == @last_statement

    "#{description(@first_statement)} - #{description(@last_statement)}"
  end

  def description(statement)
    "#{Date::MONTHNAMES[statement.month]} #{statement.year}"
  end
end
