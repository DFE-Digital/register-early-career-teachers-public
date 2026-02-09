module Schools
  class AccessController < SchoolsController
    layout "full"

    skip_before_action :redirect_if_school_access_blocked
    skip_before_action :set_school

    before_action :ensure_access_blocked!

    def show
    end

  private

    def ensure_access_blocked!
      blocker = Schools::AccessBlocker.new(school_urn: current_user.school_urn)
      return redirect_to schools_ects_home_path unless blocker.blocked?

      @school_name = blocker.school_name || current_user.school_urn
    end
  end
end
