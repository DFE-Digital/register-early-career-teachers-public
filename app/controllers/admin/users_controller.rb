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

    def remove
      @user = User.find(params[:id])
      @remove_user = Admin::Users::RemoveUserForm.new(user: @user)
    end

    def destroy
      @user = User.find(params[:id])

      @remove_user = Admin::Users::RemoveUserForm.new(
        remove_user_params.merge(
          user: @user,
          author: current_user
        )
      )

      if @remove_user.save
        redirect_to admin_users_path,
                    alert: "#{@user.name} has been removed as a user and no longer has access to the admin console"
      else
        render :remove, status: :bad_request
      end
    rescue DfEUsers::CannotRemoveSelfError
      redirect_to admin_user_path(@user),
                  notice: "You cannot remove your own user account"
    rescue DfEUsers::UserReferencedByDeclarationError
      redirect_to admin_user_path(@user),
                  notice: "This user cannot be removed because they are referenced by historical declaration records"
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
  end
end
