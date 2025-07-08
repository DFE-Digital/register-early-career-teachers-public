module Admin
  module Errors
    class TeacherAlreadyExists < StandardError
      def initialize(full_name)
        msg = "Teacher #{full_name} already exists in the system"
        super(msg)
      end
    end

    class TeacherHasActiveInductionPeriodWithAnotherAB < StandardError
      def template
        :induction_with_another_appropriate_body
      end
    end
  end
end
