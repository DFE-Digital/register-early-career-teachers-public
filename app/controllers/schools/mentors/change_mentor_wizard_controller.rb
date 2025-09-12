module Schools
  module Mentors
    # Common controller for 'mini-wizards' editing Mentor fields
    class ChangeMentorWizardController < SchoolsController
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

      # @return [MentorAtSchoolPeriod]
      def mentor_at_school_period
        @mentor_at_school_period ||= school.mentor_at_school_periods.find(params[:mentor_id])
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
