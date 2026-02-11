module Schools
  class AccessBlocker
    attr_reader :school_urn

    def initialize(school_urn:)
      @school_urn = school_urn
    end

    def blocked?
      missing_school_record? || closed_school? || no_funding?
    end

    def school_name
      school&.name || gias_school&.name
    end

  private

    def school
      @school ||= School.includes(:gias_school).find_by(urn: school_urn)
    end

    def gias_school
      @gias_school ||= school&.gias_school || GIAS::School.find_by(urn: school_urn)
    end

    def missing_school_record?
      school.nil? && gias_school.present?
    end

    def closed_school?
      gias_school&.closed?
    end

    def no_funding?
      school&.blocked_from_service_access?
    end
  end
end
