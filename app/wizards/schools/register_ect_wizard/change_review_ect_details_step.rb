module Schools
  module RegisterECTWizard
    class ChangeReviewECTDetailsStep < ReviewECTDetailsStep
      def next_step
        :check_answers
      end

      def previous_step
        :check_answers
      end
    end
  end
end
