class Admin::DfESignInOrganisationsController < AdminController
  def index
    @organisations = DfESignInOrganisation.all
  end

  def show
    @organisation = DfESignInOrganisation.find_by!(uuid: params[:id])
  end
end
