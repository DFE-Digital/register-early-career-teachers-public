class Admin::TeachingSchoolHubsController < AdminController
  layout "full"

  def index
    @teaching_school_hubs = AppropriateBody.regional
  end

  def show
    @teaching_school_hub = AppropriateBody.regional.find(params[:id])
  end
end
