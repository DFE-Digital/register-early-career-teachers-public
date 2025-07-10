module Schools
  module RegisterMentorWizard
    class EmailAddressStep < Step
      attr_accessor :email

      validates :email, presence: { message: "Enter the email address" }, notify_email: true

      def self.permitted_params
        %i[email]
      end

      def next_step
        return :cant_use_email if mentor.cant_use_email?
        return :review_mentor_eligibility if ect.provider_led_training_programme? && mentor.funding_available?

        return :check_answers unless has_mentor_at_school_periods?

        if has_open_mentor_at_school_period_at_another_school?
          # Ask school: are they mentoring at new school only?
          :mentoring_at_new_school_only
        else
          # Ask school: when will mentor start?
          :started_on
        end
      end

      def previous_step
        :review_mentor_details
      end

    private

      def mentor_at_school_periods
        ::MentorAtSchoolPeriod.includes(:teacher).where(teacher: { trn: mentor.trn })
      end

      # Does mentor have any previous mentor_at_school_periods (open or closed)?
      def has_mentor_at_school_periods?
        mentor_at_school_periods.exists?
      end

      # Does mentor have an open mentor_at_school_period at another school?
      def has_open_mentor_at_school_period_at_another_school?
        finishes_in_the_future_scope = ::MentorAtSchoolPeriod.finished_on_or_after(Date.tomorrow)
        mentor_at_school_periods.where.not(school: mentor.school).ongoing.or(finishes_in_the_future_scope).exists?
      end
    end
  end
end
