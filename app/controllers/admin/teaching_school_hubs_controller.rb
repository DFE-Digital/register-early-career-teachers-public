class Admin::TeachingSchoolHubsController < ApplicationController
  layout "full"

  def index
    @teaching_school_hubs = TeachingSchoolHub.all
  end

  def show
    @teaching_school_hub = TeachingSchoolHub.find(params[:id])
  end
end
