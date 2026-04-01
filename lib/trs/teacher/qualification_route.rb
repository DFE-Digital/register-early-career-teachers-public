class TRS::Teacher::QualificationRoute
  attr_reader :trs_route_to_professional_status

  QUALIFICATIONS = {
    "QualifiedTeacherStatus" => "QTS",
    "EarlyYearsTeacherStatus" => "EYTS",
    "EarlyYearsProfessionalStatus" => "EYPS",
    "PartialQualifiedTeacherStatus" => "PQTS"
  }.freeze

  # These are the route names returned from TRS (as at April 2026).
  # Uncomment and modify the values, to have a more human friendly route name.
  # E.g. "HEI - Historic" => "Higher Education Institution (Historic)",
  PRETTY_ACTIVE_ROUTE_NAMES = {
    # "Apply for Qualified Teacher Status in England" => "Apply for Qualified Teacher Status in England",
    # "Assessment Only" => "Assessment Only",
    # "Early Years ITT Assessment Only" => "Early Years ITT Assessment Only",
    # "Early Years ITT Graduate Employment Based" => "Early Years ITT Graduate Employment Based",
    # "Early Years ITT Graduate Entry" => "Early Years ITT Graduate Entry",
    # "Early Years ITT School Direct" => "Early Years ITT School Direct",
    # "Early Years ITT Undergraduate" => "Early Years ITT Undergraduate",
    # "Early Years Teacher Degree Apprenticeship" => "Early Years Teacher Degree Apprenticeship",
    # "Flexible ITT" => "Flexible ITT",
    # "Future Teaching Scholars" => "Future Teaching Scholars",
    # "HEI" => "HEI",
    "High Potential ITT" => "High Potential Initial Teacher Training"
    # "International Qualified Teacher Status" => "International Qualified Teacher Status",
    # "Northern Irish Recognition" => "Northern Irish Recognition",
    # "Postgraduate Teaching Apprenticeship" => "Postgraduate Teaching Apprenticeship",
    # "Primary and secondary postgraduate fee funded" => "Primary and secondary postgraduate fee funded",
    # "Primary and secondary undergraduate fee funded" => "Primary and secondary undergraduate fee funded",
    # "Provider led Postgrad" => "Provider led Postgrad",
    # "Provider led Undergrad" => "Provider led Undergrad",
    # "QTLS and SET Membership" => "QTLS and SET Membership",
    # "School Direct Training Programme" => "School Direct Training Programme",
    # "School Direct Training Programme Salaried" => "School Direct Training Programme Salaried",
    # "School Direct Training Programme Self Funded" => "School Direct Training Programme Self Funded",
    # "Scottish Recognition" => "Scottish Recognition",
    # "Teacher Degree Apprenticeship" => "Teacher Degree Apprenticeship",
    # "Undergraduate Opt In" => "Undergraduate Opt In",
    # "Welsh Recognition" => "Welsh Recognition"
  }.freeze

  PRETTY_INACTIVE_ROUTE_NAMES = {
    # "Authorised Teacher Programme" => "Authorised Teacher Programme",
    # "Core" => "Core",
    # "Core Flexible" => "Core Flexible",
    # "CTC or CCTA" => "CTC or CCTA",
    # "EC directive" => "EC directive",
    # "European Recognition" => "European Recognition",
    # "European Recognition - PQTS" => "European Recognition - PQTS",
    # "EYPS" => "EYPS",
    # "EYPS ITT Migrated" => "EYPS ITT Migrated",
    # "EYTS ITT Migrated" => "EYTS ITT Migrated",
    # "FE Recognition 2000-2004" => "FE Recognition 2000-2004",
    # "Graduate non-trained" => "Graduate non-trained",
    # "Graduate Teacher Programme" => "Graduate Teacher Programme",
    "HEI - Historic" => "Higher Education Institution (Historic)",
    # "Legacy ITT" => "Legacy ITT",
    # "Legacy Migration" => "Legacy Migration",
    # "Licensed Teacher Programme" => "Licensed Teacher Programme",
    # "Licensed Teacher Programme - Armed Forces" => "Licensed Teacher Programme - Armed Forces",
    # "Licensed Teacher Programme - FE" => "Licensed Teacher Programme - FE",
    # "Licensed Teacher Programme - Independent School" => "Licensed Teacher Programme - Independent School",
    # "Licensed Teacher Programme - Maintained School" => "Licensed Teacher Programme - Maintained School",
    # "Licensed Teacher Programme - OTT" => "Licensed Teacher Programme - OTT",
    # "Long Service" => "Long Service",
    # "Other Qualifications non ITT" => "Other Qualifications non ITT",
    # "Overseas Trained Teacher Programme" => "Overseas Trained Teacher Programme",
    # "Overseas Trained Teacher Recognition" => "Overseas Trained Teacher Recognition",
    # "PGATC ITT" => "PGATC ITT",
    # "PGATD ITT" => "PGATD ITT",
    "PGCE ITT" => "Postgrad Certificate in Education"
    # "PGDE ITT" => "PGDE ITT",
    # "ProfGCE ITT" => "ProfGCE ITT",
    # "ProfGDE ITT" => "ProfGDE ITT",
    # "Registered Teacher Programme" => "Registered Teacher Programme",
    # "School Centered ITT" => "School Centered ITT",
    # "TC ITT" => "TC ITT",
    # "TCMH" => "TCMH",
    # "Teach First Programme" => "Teach First Programme",
    # "Troops to Teach" => "Troops to Teach",
    # "UGMT ITT" => "UGMT ITT"
  }.freeze

  PRETTY_ROUTE_NAMES = PRETTY_ACTIVE_ROUTE_NAMES.merge(PRETTY_INACTIVE_ROUTE_NAMES).freeze

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
    raw_route_name = route_to_professional_status_type["name"]
    PRETTY_ROUTE_NAMES.fetch(raw_route_name, raw_route_name)
  end
end
