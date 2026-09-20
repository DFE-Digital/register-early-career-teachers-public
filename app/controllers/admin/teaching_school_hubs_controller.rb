class Admin::TeachingSchoolHubsController < AdminController
  layout "full"

  def index
    @teaching_school_hubs = TeachingSchoolHub.order(:name)
  end

  def show
    @teaching_school_hub = TeachingSchoolHub.find(params[:id])
  end
end
