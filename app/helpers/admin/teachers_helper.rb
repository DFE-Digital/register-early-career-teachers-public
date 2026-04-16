module Admin::TeachersHelper
  FilterOption = Data.define(:value, :name)

  def teacher_role_filter_options
    Admin::Teachers::Search::ROLE_NAMES.map do |value, name|
      FilterOption.new(value:, name:)
    end
  end

  def teacher_contract_period_filter_options
    filter_options = ContractPeriod.order(:year).map do |contract_period|
      year = contract_period.year.to_s

      FilterOption.new(value: year, name: year)
    end

    filter_options + [FilterOption.new(value: Admin::Teachers::Search::CONTRACT_PERIOD_NOT_AVAILABLE, name: "Not available")]
  end
end
