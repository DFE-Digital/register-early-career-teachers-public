module Admin
  class UsersController < AdminController
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
  end
end
