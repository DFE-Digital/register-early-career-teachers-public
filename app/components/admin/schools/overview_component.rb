class Admin::Schools::OverviewComponent < ApplicationComponent
  attr_reader :school

  def initialize(school:)
    @school = school
  end

  def induction_tutor_name
    school.induction_tutor_name.presence || "Not set"
  end

  def induction_tutor_email
    school.induction_tutor_email.presence || "Not set"
  end

  def local_authority_name
    school.local_authority_name.presence || "Not available"
  end

  def section_41_status
    school.section_41_approved? ? "Approved" : "Not approved"
  end

  def establishment_type
    school.type_name
  end

  def administrative_district
    school.administrative_district_name.presence || "Not available"
  end

  def status
    school.status.capitalize
  end

  def address
    address_lines = [school.address_line1, school.address_line2, school.address_line3, school.postcode].compact_blank
    if address_lines.any?
      safe_join(address_lines, tag.br)
    else
      "Not available"
    end
  end
end
