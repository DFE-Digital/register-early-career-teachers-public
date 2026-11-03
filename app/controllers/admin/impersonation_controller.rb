module Admin
  class ImpersonationController < AdminController
    class InvalidUserType < StandardError; end

    skip_before_action :authorise, only: :destroy

    def create
      if params[:school_urn]
        session["user_session"] = current_user
          .build_impersonate_school_user_session(params[:school_urn])
        redirect_to schools_ects_home_path
      elsif params[:appropriate_body_period_id]
        session["user_session"] = current_user
          .build_impersonate_appropriate_body_user_session(params[:appropriate_body_period_id])
        redirect_to ab_teachers_path
      else
        fail InvalidUserType
      end
    end

    def destroy
      if current_user.dfe_user_impersonating_school_user?
        urn = current_user.school.urn
        session["user_session"] = current_user.rebuild_original_session
        redirect_to admin_school_overview_path(urn)
      elsif current_user.dfe_user_impersonating_appropriate_body_user?
        appropriate_body_period_id = current_user.appropriate_body_period_id
        session["user_session"] = current_user.rebuild_original_session
        redirect_to admin_appropriate_body_path(appropriate_body_period_id)
      else
        fail InvalidUserType
      end
    end
  end
end
