class Statements::Period
  def self.for(statement)
    new(statement.year, statement.month).to_s
  end

  def self.from_year_and_month(year, month)
    new(year, month).to_s
  end

  def initialize(year, month)
    @year = year
    @month = month
  end

  def to_s
    month_name = Date::MONTHNAMES.fetch(@month)
    "#{month_name} #{@year}"
  end
end
