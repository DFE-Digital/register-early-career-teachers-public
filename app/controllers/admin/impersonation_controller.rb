module Admin
  class ImpersonationController < AdminController
    def create
      session['user_session'] = current_user.build_impersonate_school_user_session(params[:school_urn])

      redirect_to schools_ects_home_path
    end

    def destroy
      urn = current_user.school.urn

      session['user_session'] = current_user.rebuild_original_session

      redirect_to admin_school_overview_path(urn)
    end
  end
end
