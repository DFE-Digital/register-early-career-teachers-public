module ContractPeriodYearConcern
  extend ActiveSupport::Concern

  def to_year(value)
    case value
    when Integer then value
    when String  then value.to_i
    else
      value.respond_to?(:year) ? value.year : value.to_i
    end
  end
end
