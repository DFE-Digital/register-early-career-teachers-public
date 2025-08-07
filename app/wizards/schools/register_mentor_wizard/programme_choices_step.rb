module Schools
  module RegisterMentorWizard
    class ProgrammeChoicesStep < Step
      attr_accessor :use_same_programme_choices

      validates :use_same_programme_choices, inclusion: { in: %w[yes no], message: "Select 'Yes' or 'No'" }

      def self.permitted_params
        %i[use_same_programme_choices]
      end

      def next_step
        if use_same_programme_choices == "yes"
          :check_answers
        else
          :lead_provider
        end
      end

      def previous_step
        if mentor.latest_registration_choice.school_partnership
          :previous_training_period_details
        else
          :started_on
        end
      end

    private

      def persist
        mentor.update!(use_same_programme_choices:, lead_provider_id:)
      end

      def lead_provider_id
        if use_same_programme_choices == "yes"
          mentor.ect_lead_provider&.id || mentor.ect_eoi_lead_provider&.id
        end
      end
    end
  end
end
