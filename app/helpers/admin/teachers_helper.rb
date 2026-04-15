module Admin::TeachersHelper
  FilterOption = Data.define(:value, :name)

  def teacher_role_filter_options
    [
      FilterOption.new(value: "ect", name: "Early career teacher"),
      FilterOption.new(value: "mentor", name: "Mentor"),
    ]
  end

  def teacher_contract_period_filter_options
    filter_options = ContractPeriod.order(:year).map do |contract_period|
      year = contract_period.year.to_s

      FilterOption.new(value: year, name: year)
    end

    filter_options + [FilterOption.new(value: "not_available", name: "Not available")]
  end
end
