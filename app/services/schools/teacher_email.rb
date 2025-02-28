module Schools
  class TeacherEmail
    def initialize(email:, trn:)
      @email = email
      @trn = trn
    end

    def is_currently_used?
      email_in_use_by_ongoing_ect? || email_in_use_by_ongoing_mentor?
    end

  private

    attr_reader :email, :trn

    def email_in_use_by_ongoing_mentor?
      MentorAtSchoolPeriod.joins(:teacher).where(email:).where.not(teacher: { trn: }).ongoing.exists?
    end

    def email_in_use_by_ongoing_ect?
      ECTAtSchoolPeriod.joins(:teacher).where(email:).where.not(teacher: { trn: }).ongoing.exists?
    end
  end
end
