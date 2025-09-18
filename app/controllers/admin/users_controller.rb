module Admin
  class UsersController < AdminController
    def index
      @users = User.all
    end

    def show
      @user = User.includes(:dfe_roles).find(params[:id])
    end

    def new
      @user = User.new
    end

    def create
      @user = User.new(user_params)

      if @user.save
        flash[:notice] = "#{@user.name} added"
        redirect_to admin_users_path
      else
        render :new
      end
    end

    def edit
      @user = User.find(params[:id])
    end

    def update
      @user = User.find(params[:id])

      @user.assign_attributes(user_params)

      if @user.save
        flash[:notice] = "#{@user.name} updated"
        redirect_to admin_users_path
      else
        render :edit
      end
    end

  private

    def user_params
      params.expect(user: %i[name email])
    end
  end
end
