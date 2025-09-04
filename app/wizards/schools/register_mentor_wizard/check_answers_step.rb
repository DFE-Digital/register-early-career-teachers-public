module Schools
  module RegisterMentorWizard
    class CheckAnswersStep < Step
      def next_step
        :confirmation
      end

      def previous_step
        case options
        in { pop_back_to_eligibility_lead_provider: true }
          :eligibility_lead_provider
        in { mentored_before: true, mentoring_at_new_school_only: true }
          :mentoring_at_new_school_only
        in { mentored_before: true, use_same_programme_choices: true }
          :programme_choices
        in { mentored_before: true, use_same_programme_choices: false }
          :lead_provider
        in { ect_provider_led: true, mentor_funding_available: true }
          :review_mentor_eligibility
        else
          :email_address
        end
      end

    private

      def options
        {
          pop_back_to_eligibility_lead_provider: pop_back_to!(:eligibility_lead_provider),
          mentored_before: mentor.previously_registered_as_mentor?,
          mentoring_at_new_school_only: mentoring_at_new_school_only?,
          use_same_programme_choices: use_same_programme_choices?,
          ect_provider_led: ect.provider_led_training_programme?,
          mentor_funding_available: mentor.funding_available?
        }
      end

      def pop_back_to!(key)
        return false unless store.back_to.to_s == key.to_s

        store.back_to = nil
        true
      end

      def mentoring_at_new_school_only?
        store.mentoring_at_new_school_only == 'no'
      end

      def use_same_programme_choices?
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
