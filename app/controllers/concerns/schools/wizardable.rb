module Schools
  module Wizardable
    extend ActiveSupport::Concern

    WIZARDABLE_TYPES = %i[ect mentor].freeze

    class_methods do
      def wizard_for(type)
        raise ArgumentError, "Unsupported wizard type" unless type.in?(WIZARDABLE_TYPES)

        self.wizardable_type = type
      end
    end

    included do
      class_attribute :wizardable_type

      before_action :set_steps,
                    :set_store,
                    :set_record,
                    :set_wizard

      before_action -> { redirect_to "/404", as: :not_found },
                    unless: -> { wizard_class.step?(@current_step) }

      before_action -> { @wizard.reset },
                    if: -> { @current_step == :edit },
                    unless: -> { @previous_step == :check_answers },
                    only: :new

    private

      def set_steps
        @current_step = request.path.split("/").last.underscore.to_sym
        @previous_step = request.referer&.split("/")&.last&.underscore&.to_sym
      end

      def set_store
        @store = SessionRepository.new(session:, form_key:)
      end

      def set_record
        instance_variable_set(
          "@#{wizard_record_name}",
          @school
            .public_send(wizard_record_name.pluralize)
            .find(params[wizard_record_param])
        )
      end

      def set_wizard
        @wizard = wizard_class.new(
          current_step: @current_step,
          author: current_user,
          step_params: params,
          store: @store,
          wizard_record_name => instance_variable_get("@#{wizard_record_name}")
        )
      end

      def wizard_class
        self.class.to_s.delete_suffix("Controller").concat("::Wizard").constantize
      end

      def form_key
        self.class.to_s.delete_suffix("Controller").underscore
      end

      def wizard_record_param
        "#{wizardable_type}_id"
      end

      def wizard_record_name
        "#{wizardable_type}_at_school_period"
      end
    end
  end
end
