module Schools
  module ECTs
    class Wizard < ApplicationWizard
      attr_accessor :store, :ect_at_school_period, :author

      def self.step?(step_name)
        Array(steps).first[step_name].present?
      end

      # @return [String]
      def teacher_full_name
        ::Teachers::Name.new(ect_at_school_period.teacher.reload).full_name
      end

      # @return [Hash]
      def default_path_arguments
        { ect_id: ect_at_school_period.id }
      end

      # There is no #current_step_path_arguments method
      # https://github.com/DFE-Digital/dfe-wizard/blob/main/lib/dfe/wizard/step.rb#L54-L60
      # https://github.com/DFE-Digital/dfe-wizard/blob/main/lib/dfe/wizard/base.rb#L117-L119
      #
      # @return [String]
      def current_step_path
        super(default_path_arguments)
      end
    end
  end
end
