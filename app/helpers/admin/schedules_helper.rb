module Admin::SchedulesHelper
  SCHEDULE_MAPPINGS = {
    # standard
    "ecf-standard-april" => "Standard April",
    "ecf-standard-january" => "Standard January",
    "ecf-standard-september" => "Standard September",
    # extended
    "ecf-extended-april" => "Extended April",
    "ecf-extended-january" => "Extended January",
    "ecf-extended-september" => "Extended September",
    # reduced
    "ecf-reduced-april" => "Reduced April",
    "ecf-reduced-january" => "Reduced January",
    "ecf-reduced-september" => "Reduced September",
    # replacement
    "ecf-replacement-april" => "Replacement April",
    "ecf-replacement-january" => "Replacement January",
    "ecf-replacement-september" => "Replacement September",
  }.freeze

  def schedule_name(identifier)
    SCHEDULE_MAPPINGS.fetch(identifier, identifier.humanize)
  end
end
