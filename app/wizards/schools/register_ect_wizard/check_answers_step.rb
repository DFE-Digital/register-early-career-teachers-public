module Schools
  module RegisterECTWizard
    class CheckAnswersStep < Step
      def next_step
        :confirmation
      end

      def previous_step
        return :funding_ind_appropriate_body if independent_school?

        :appropriate_body
      end

    private

      def persist
        ect_at_school_period_id = ect.register!.id
        ect.update!(ect_at_school_period_id:)
      end
    end
  end
end
