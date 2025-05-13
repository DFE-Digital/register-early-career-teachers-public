module Teachers
  class CurrentSchools
    def initialize(trn:)
      @teacher = Teacher.find_by(trn:)
    end

    def ect_at
      return unless @teacher

      @teacher.ect_at_school_periods.ongoing.first&.school
    end
  end
end
