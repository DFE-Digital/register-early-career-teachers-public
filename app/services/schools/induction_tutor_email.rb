module Schools
  class InductionTutorEmail
    attr_reader :school

    def initialize(school:)
      @school = school
    end

    def email
      school.induction_tutor_email
    end

    def email_or_gias_contact
      email.presence || school.gias_school.primary_contact_email.presence || school.gias_school.secondary_contact_email
    end
  end
end
