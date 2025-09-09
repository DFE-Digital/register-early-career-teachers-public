module Schools
  module ECTs
    # Common controller for 'mini-wizards' editing ECT fields
    class ChangeECTWizardController < SchoolsController
      before_action :initialize_wizard, only: %i[new create]
      before_action :reset_wizard, only: :new

      def new
        render current_step
      end

      def create
        if @wizard.valid_step?
          @wizard.current_step.save!
          redirect_to @wizard.next_step_path
        else
          render current_step
        end
      end

    private

      # @return [ECTAtSchoolPeriod]
      def ect_at_school_period
        @ect_at_school_period ||= school.ect_at_school_periods.find(params[:ect_id])
      end

      # @return [Symbol]
      def current_step
        request.path.split('/').last.underscore.to_sym
      end

      # @return [nil]
      def reset_wizard
        @wizard.store.reset if current_step == :edit
      end
    end
  end
end
