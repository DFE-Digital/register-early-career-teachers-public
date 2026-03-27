class TRS::Teacher::QualificationRoute
  attr_reader :trs_route_to_professional_status

  QUALIFICATIONS = {
    "QualifiedTeacherStatus" => "QTS",
    "EarlyYearsTeacherStatus" => "EYTS",
    "EarlyYearsProfessionalStatus" => "EYPS",
    "PartialQualifiedTeacherStatus" => "PQTS"
  }.freeze

  class << self
    def to_summary(trs_routes_to_professional_status)
      trs_routes_to_professional_status.map do |trs_route_to_professional_status|
        new(trs_route_to_professional_status).to_summary
      end
    end
  end

  def initialize(trs_route_to_professional_status)
    @trs_route_to_professional_status = trs_route_to_professional_status
  end

  def to_summary
    parts.join " "
  end

private

  def parts
    result = [status, formatted_qualification]
    result += ["from", holds_from_as_date] if holds_from.present?
    result + ["via", route_name]
  end

  def holds_from
    trs_route_to_professional_status["holdsFrom"]
  end

  def holds_from_as_date
    Date.parse(holds_from).strftime("%d %b %Y")
  rescue Date::Error
    holds_from
  end

  def route_to_professional_status_type
    trs_route_to_professional_status.fetch("routeToProfessionalStatusType", {})
  end

  def status
    trs_route_to_professional_status["status"]
  end

  def formatted_qualification
    # Fall back to raw_qualification if qualification is unknown
    QUALIFICATIONS.fetch raw_qualification, raw_qualification.to_s.titleize
  end

  def raw_qualification
    route_to_professional_status_type["professionalStatusType"]
  end

  def route_name
    route_to_professional_status_type["name"]
  end
end
