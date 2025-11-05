class Admin::DfESignInOrganisationsController < AdminController
  def show
    @organisation = DfESignInOrganisation.find_by!(uuid: params[:id])
  end
end
