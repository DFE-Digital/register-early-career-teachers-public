module Schools
  module RegisterMentorWizard
    class MentoringAtNewSchoolOnlyStep < Step
      attr_accessor :mentoring_at_new_school_only

      validates :mentoring_at_new_school_only,
                inclusion: { in: %w[yes no],
                             message: "Select 'Yes' or 'No' to confirm whether they will be mentoring at your school only" }

      def self.permitted_params
        %i[mentoring_at_new_school_only]
      end

      def next_step
        # Ask school: are they mentoring at new school only?
        if mentoring_at_new_school_only == "yes"
          :started_on
        else
          :check_answers
        end
      end

      def previous_step
        :email_address
      end

    private

      def persist
        mentor.update!(mentoring_at_new_school_only:)
      end
    end
  end
end
