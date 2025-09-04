module Schools
  module RegisterMentorWizard
    class CheckAnswersStep < Step
      def next_step
        :confirmation
      end

      def previous_step
        case
        when pop_back_to!(:eligibility_lead_provider)
          :eligibility_lead_provider
        when mentor.previously_registered_as_mentor?
          if user_chose_no_to_mentoring_at_new_school_only?
            :mentoring_at_new_school_only
          elsif user_chose_yes_to_use_same_programme_choices?
            :programme_choices
          else
            :lead_provider
          end
        when ect.provider_led_training_programme? && mentor.funding_available?
          :review_mentor_eligibility
        else
          :email_address
        end
      end

    private

      def pop_back_to!(key)
        return false unless store.back_to.to_s == key.to_s

        store.back_to = nil
        true
      end

      def user_chose_no_to_mentoring_at_new_school_only?
        store.mentoring_at_new_school_only == 'no'
      end

      def user_chose_yes_to_use_same_programme_choices?
        store.use_same_programme_choices == 'yes'
      end

      def persist
        ActiveRecord::Base.transaction do
          AssignMentor.new(ect:, author:, mentor: mentor.register!(author:)).assign!
        end
      rescue StandardError => e
        mentor.registered = false
        raise e
      end
    end
  end
end
