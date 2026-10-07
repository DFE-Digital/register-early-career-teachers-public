module Admin
  module Schools
    class AddPartnershipWizardController < AdminController
      layout "full"

      FORM_KEY = "admin_schools_add_partnership_wizard"

      before_action :set_school
      before_action :reset_store_on_entry
      before_action :initialize_wizard
      before_action :check_allowed_step

      def new
        if current_step == :check_answers
          @review = Admin::Schools::AddPartnershipReview.new(@wizard)
        end

        render current_step
      end

      def create
        if @wizard.save_current_step
          if current_step == :check_answers
            redirect_to admin_school_partnerships_path(@school.urn), alert: "Partnership added"
          else
            redirect_to @wizard.next_step_path
          end
        else
          if current_step == :check_answers
            @review = Admin::Schools::AddPartnershipReview.new(@wizard)
          end

          render current_step
        end
      end

    private

      def set_school
        @school = School.includes(:gias_school).find_by!(urn: params[:school_urn])
      end

      def check_allowed_step
        return if @wizard.valid_path_to_current_step?

        redirect_to @wizard.furthest_valid_step_path
      end

      def state_store
        @state_store ||= Admin::Schools::AddPartnershipWizard::StateStore.new(
          school: @school,
          repository: DfE::Wizard::Repository::Session.new(
            session:,
            key: FORM_KEY
          )
        )
      end

      def current_step
        @current_step ||= request.path.split("/").last.underscore.to_sym
      end

      def initialize_wizard
        @wizard = Admin::Schools::AddPartnershipWizard::Wizard.new(
          current_step:,
          current_step_params: params,
          author: current_user,
          state_store:
        )
      end

      def reset_store_on_entry
        return unless current_step == :select_contract_period
        return if request.referer.to_s.include?("/partnerships/add/")

        state_store.clear
      end
    end
  end
end
