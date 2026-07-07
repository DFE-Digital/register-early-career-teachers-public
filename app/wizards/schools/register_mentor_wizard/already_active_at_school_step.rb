module Schools
  module RegisterMentorWizard
    class AlreadyActiveAtSchoolStep < Step
      def next_step
        :confirmation
      end

    private

      def persist
        mentor.update!(already_active_at_school: true)
        AssignMentor.new(
          ect_at_school_period: ect,
          mentor_at_school_period: mentor.active_record_at_school,
          author:
        ).assign!
      end
    end
  end
end
