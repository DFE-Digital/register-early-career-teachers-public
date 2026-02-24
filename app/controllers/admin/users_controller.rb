module Admin
  class UsersController < AdminController
    before_action :require_users_access!
    def index
      @users = User.alphabetical
    end

    def show
      @user = User.find(params[:id])
    end

    def new
      @user = User.new
    end

    def create
      dfe_users = DfEUsers.new(author: current_user)

      if dfe_users.create_user(user_params)
        flash[:notice] = "#{dfe_users.user.name} added"
        redirect_to admin_users_path
      else
        @user = dfe_users.user
        render :new, status: :bad_request
      end
    end

    def edit
      @user = User.find(params[:id])
    end

    def update
      dfe_users = DfEUsers.new(author: current_user)

      if dfe_users.update_user(params[:id], user_params)
        flash[:notice] = "#{dfe_users.user.name} updated"
        redirect_to admin_users_path
      else
        @user = dfe_users.user
        render :edit, status: :bad_request
      end
    end

  private

    def user_params
      permitted_attributes = %i[name email role]
      permitted_attributes << :otp_school_urn if otp_school_sign_in_enabled?

      params.expect(user: permitted_attributes)
    end

    def otp_school_sign_in_enabled?
      Rails.application.config.enable_otp_school_sign_in
    end

    def require_users_access!
      return if current_user&.dfe_user? && current_user.can_manage_users?

      @unauthorised_context = :users
      render "errors/unauthorised", status: :unauthorized
    end
  end
end
