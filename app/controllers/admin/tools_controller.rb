module Admin
  class ToolsController < AdminController
    def show
    end

  private

    def authorised? = super && current_user.product_team?
  end
end
