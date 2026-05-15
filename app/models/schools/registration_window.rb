module Schools
  class RegistrationWindow
    CLOSED_PERIOD = Date.new(2026, 6, 1)..Date.new(2026, 6, 14)

    def self.closed?
      CLOSED_PERIOD.cover?(Date.current)
    end

    def self.reopens_on
      CLOSED_PERIOD.end + 1.day
    end
  end
end
