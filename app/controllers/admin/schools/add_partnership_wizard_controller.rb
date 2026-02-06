module Admin
  module Schools
    class AddPartnershipWizardController < AdminController
      layout "full"

      FORM_KEY = "admin_schools_add_partnership_wizard"

      before_action :set_school
      before_action :initialize_wizard
      before_action :check_allowed_step
      before_action :reset_store_on_entry

      def new
        render current_step
      end

      def create
        if @wizard.valid_step?
          @wizard.current_step.save!

          if current_step == :check_answers
            redirect_to admin_school_partnerships_path(@school.urn), alert: "Partnership added"
          else
            redirect_to @wizard.next_step_path
          end
        else
          render current_step
        end
      end

    private

      def set_school
        @school = School.includes(:gias_school).find_by!(urn: params[:school_urn])
      end

      def check_allowed_step
        redirect_to @wizard.allowed_step_path unless @wizard.allowed_step?
      end

      def store
        @store ||= SessionRepository.new(session:, form_key: FORM_KEY)
      end

      def current_step
        @current_step ||= begin
          step = step_name_from_path
          return :not_found unless wizard_class.step?(step)

          step
        end
      end

      def step_name_from_path
        request.path.split("/").last.underscore.to_sym
      end

      def initialize_wizard
        @wizard = wizard_class.new(
          current_step:,
          step_params: params,
          author: current_user,
          school_urn: @school.urn,
          store:
        )
      end

      def wizard_class
        Admin::Schools::AddPartnershipWizard::Wizard
      end

      def reset_store_on_entry
        return unless current_step == :select_contract_period
        return if request.referer.to_s.include?("/partnerships/add/")

        store.reset
      end
    end
  end
end
