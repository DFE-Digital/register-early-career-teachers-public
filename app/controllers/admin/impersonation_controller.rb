module Admin
  class ImpersonationController < AdminController
    class InvalidUserType < StandardError; end

    skip_before_action :authorise, only: :destroy

    def create
      session['user_session'] = current_user.build_impersonate_school_user_session(params[:school_urn])

      redirect_to schools_ects_home_path
    end

    def destroy
      fail InvalidUserType unless current_user.dfe_user_impersonating_school_user?

      urn = current_user.school.urn

      session['user_session'] = current_user.rebuild_original_session

      redirect_to admin_school_overview_path(urn)
    end
  end
end
