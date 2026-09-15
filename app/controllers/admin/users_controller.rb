module Admin
  class UsersController < AdminController
    before_action :require_users_access!
    before_action :require_user_manager!, only: %i[remove destroy]

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

    def remove
      @user = User.find(params[:id])
      @remove_user = Admin::Users::RemoveUserForm.new(
        user_name: @user.name
      )
    end

    def destroy
      @user = User.find(params[:id])

      @remove_user = Admin::Users::RemoveUserForm.new(
        remove_user_params.merge(user_name: @user.name)
      )

      unless @remove_user.valid?
        render :remove, status: :bad_request
        return
      end

      user_name = @user.name

      dfe_users = DfEUsers.new(author: current_user)
      dfe_users.remove_user(@user.id)

      redirect_to admin_users_path,
                  notice: "#{user_name} has been removed as a user and no longer has access to the admin console"
    end

    def unlock_otp_sign_in
      user = User.find(params[:id])

      Sessions::UnlockOTPAccount.new(author: current_user, user:).unlock

      redirect_to admin_user_path(user), alert: "#{user.name} can now sign in with OTP"
    end

  private

    def user_params
      params.expect(user: %i[name email role])
    end

    def require_users_access!
      return if current_user&.dfe_user? && current_user.can_manage_users?

      @unauthorised_context = :users
      render "errors/unauthorised", status: :unauthorized
    end

    def remove_user_params
      params.fetch(:admin_users_remove_user_form, {}).permit(:confirmed)
    end

    def require_user_manager!
      return if current_user&.dfe_user? && current_user.user_manager?

      @unauthorised_context = :users
      render "errors/unauthorised", status: :unauthorized
    end
  end
end
