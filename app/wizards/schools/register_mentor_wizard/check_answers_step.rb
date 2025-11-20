module Schools
  module RegisterMentorWizard
    class CheckAnswersStep < Step
      def next_step
        :confirmation
      end

      def previous_step
        case
        when pop_back_to!(:eligibility_lead_provider) then :eligibility_lead_provider
        when mentor.ect_lead_provider_invalid? then :lead_provider
        when mentor.previously_registered_as_mentor?
          if mentoring_at_new_school_only?
            same_programme_choices? ? :programme_choices : :lead_provider
          else
            :mentoring_at_new_school_only
          end
        when provider_led_with_funding? then :review_mentor_eligibility
        else
          :email_address
        end
      end

    private

      def provider_led_with_funding?
        ect.provider_led_training_programme? && mentor.eligible_for_funding?
      end

      def pop_back_to!(key)
        return false unless store.back_to.to_s == key.to_s

        store.back_to = nil
        true
      end

      def mentoring_at_new_school_only?
        store.mentoring_at_new_school_only == "yes"
      end

      def same_programme_choices?
        store.use_same_programme_choices == "yes"
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
