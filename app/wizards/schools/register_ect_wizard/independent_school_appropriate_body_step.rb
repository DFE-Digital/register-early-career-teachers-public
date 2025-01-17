module Schools
  module RegisterECTWizard
    class IndependentSchoolAppropriateBodyStep < Step
      attr_accessor :appropriate_body_name, :appropriate_body_type

      validates_with AppropriateBodyValidator

      def self.permitted_params
        %i[appropriate_body_name appropriate_body_type]
      end

      def next_step
        :programme_type
      end

      def previous_step
        :start_date
      end

      def persist
        name = appropriate_body_type == 'ISTIP' ? appropriate_body_type : appropriate_body_name
        ect.update!(appropriate_body_name: name)
      end
    end
  end
end
