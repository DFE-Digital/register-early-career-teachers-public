module API
  module FilterByRegistrationPeriod
    extend ActiveSupport::Concern

  protected

    def registration_period_start_years
      params.dig(:filter, :cohort)
    end
  end
end
