class Admin::TeachingSchoolHubsController < AdminController
  layout "full"

  def index
    @hubs_with_concurrent_appropriate_body_periods, @other_hubs =
      hubs.order(:name).partition(&:concurrent_appropriate_body_periods?)
  end

  def show
    @teaching_school_hub = hubs.find(params[:id])
  end

private

  def hubs
    TeachingSchoolHub.strict_loading.includes(
      appropriate_body_periods: [
        { provisioning_school: :gias_school },
        { region_awards: [:region, { school: :gias_school }] }
      ]
    )
  end
end
