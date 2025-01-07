module Schools
  module RegisterMentorWizard
    class AlreadyActiveAtSchoolStep < Step
      def next_step
        :confirmation
      end

    private

      def persist
        mentor.update!(already_active_at_school: true)
        AssignMentor.new(ect:, mentor: mentor.active_record_at_school).assign!
      end
    end
  end
end
