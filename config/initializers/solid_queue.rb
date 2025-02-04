if Rails.env.production?
  module SupervisorSafety
    def supervisees
      return [] if supervisor.nil?
      super
    end
  end

  module SolidQueue
    class Process
      class << self
        prepend SupervisorSafety
      end
    end
  end
end
