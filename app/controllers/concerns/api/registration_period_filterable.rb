module API
  module RegistrationPeriodFilterable
    extend ActiveSupport::Concern

  protected

    def registration_period_years
      params.dig(:filter, :cohort)
    end
  end
end
