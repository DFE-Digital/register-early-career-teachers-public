module Teachers
  class Anonymise
    class NotPermittedError < StandardError; end

    attr_reader :teacher, :reason

    def initialize(teacher:, reason:)
      @teacher = teacher
      @reason = reason
    end

    def anonymise!
      raise NotPermittedError, "Teacher still has registrations or induction periods" unless permitted?

      teacher.update!(
        trs_first_name: nil,
        trs_last_name: nil,
        corrected_name: nil,
        trn: nil,
        trnless: true,
        anonymisation_reason: reason,
        anonymised_at: Time.zone.now
      )
    end

    def permitted?
      teacher.induction_periods.none? &&
        teacher.ect_at_school_periods.reload.none? &&
        teacher.mentor_at_school_periods.reload.none?
    end
  end
end
