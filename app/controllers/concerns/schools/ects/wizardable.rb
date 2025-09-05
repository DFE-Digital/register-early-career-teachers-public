module Schools
  module ECTs
    module Wizardable
      extend ActiveSupport::Concern

      included do
        before_action :set_current_step,
                      :set_store,
                      :set_ect_at_school_period,
                      :set_wizard

        before_action -> { redirect_to "/404", as: :not_found },
                      unless: -> { wizard_class.step?(@current_step) }

        before_action -> { @wizard.reset },
                      if: -> { @current_step == :edit },
                      only: :new

      private

        def set_current_step
          @current_step = request.path.split("/").last.underscore.to_sym
        end

        def set_store
          @store = SessionRepository.new(session:, form_key:)
        end

        def set_ect_at_school_period
          @ect_at_school_period = @school
            .ect_at_school_periods
            .find(params[:ect_id])
        end

        def set_wizard
          @wizard = wizard_class.new(
            current_step: @current_step,
            author: current_user,
            step_params: params,
            store: @store,
            ect_at_school_period: @ect_at_school_period
          )
        end

        def wizard_class
          self.class.to_s.delete_suffix("Controller").concat("::Wizard").constantize
        end

        def form_key
          self.class.to_s.delete_suffix("Controller").underscore
        end
      end
    end
  end
end
