module Schools
  module RegisterECTWizard
    class ChangeStartDateStep < StartDateStep
      def next_step
        :check_answers
      end

      def previous_step
        :check_answers
      end

      def save!
        super.tap do |result|
          next unless result

          ect.use_previous_ect_choices = nil
          wizard.store[:school_partnership_to_reuse_id] = nil
        end
      end
    end
  end
end
