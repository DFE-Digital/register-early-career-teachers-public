module Schools
  module RegistrationWindowRedirectable
    extend ActiveSupport::Concern

    included do
      before_action :redirect_if_registration_window_closed
    end

  private

    def redirect_if_registration_window_closed
      redirect_to schools_registration_window_closed_path if RegistrationWindow.closed?
    end
  end
end
