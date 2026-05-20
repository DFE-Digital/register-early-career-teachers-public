module Admin::SchedulesHelper
  def schedule_name(identifier)
    identifier.delete_prefix("ecf-").titleize
  end
end
