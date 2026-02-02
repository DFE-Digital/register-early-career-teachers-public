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
      params.expect(user: %i[name email role])
    end

    def require_users_access!
      return if current_user&.dfe_user? && current_user.can_manage_users?

      flash[:alert] = "This is to access internal user information for Register early career teachers. To gain access, contact the product team."
      redirect_to admin_path
    end
  end
end
