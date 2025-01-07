module Schools
  module RegisterECTWizard
    class ProgrammeTypeStep < Step
      attr_accessor :programme_type

      validates :programme_type, programme_type: true

      def self.permitted_params
        %i[programme_type]
      end

      def next_step
        :check_answers
      end
    end
  end
end
