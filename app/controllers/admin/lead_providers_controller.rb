module Admin
  class LeadProvidersController < AdminController
    layout 'full'

    def index
      @breadcrumbs = {
        "Organisations" => admin_organisations_path,
        "Lead providers" => nil,
      }
      @lead_providers = ::LeadProvider.alphabetical
    end
  end
end
