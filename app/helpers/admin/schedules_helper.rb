module Admin::SchedulesHelper
  def schedule_name(identifier)
    identifier.delete_prefix("ecf-").titleize
  end

  def sort_schedules(contract_period)
    contract_period.schedules.sort_by { |s| ::Schedule.identifiers.keys.index(s.identifier) }
  end
end
