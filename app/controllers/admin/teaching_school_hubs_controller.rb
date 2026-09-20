class Admin::TeachingSchoolHubsController < AdminController
  layout "full"

  def index
    @teaching_school_hubs = TeachingSchoolHub.order(:name)
  end

  def show
    @teaching_school_hub = TeachingSchoolHub.includes(
      appropriate_body_periods: [
        { provisioning_school: :gias_school },
        { region_awards: [:region, { school: :gias_school }] }
      ]
    ).find(params[:id])
  end
end
