module Schools
  module RegisterECTWizard
    class StateSchoolAppropriateBodyStep < Step
      attr_accessor :appropriate_body_name

      validates :appropriate_body_name, presence: { message: "Enter the name of the appropriate body which will be supporting the ECT's induction" }

      def self.permitted_params
        %i[appropriate_body_name]
      end

      def next_step
        :programme_type
      end

      def previous_step
        :start_date
      end
    end
  end
end
