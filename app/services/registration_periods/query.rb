module RegistrationPeriods
  class Query
    def on(date)
      RegistrationPeriod.find_by(date)
    end

    def current
      on(Time.zone.today)
    end
  end
end
