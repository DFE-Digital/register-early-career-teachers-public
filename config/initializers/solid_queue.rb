if Rails.env.production?
  module SolidQueue
    class Process
      class << self
        alias_method :original_supervisees, :supervisees

        def supervisees
          return [] unless supervisor
          original_supervisees
        end
      end
    end
  end
end
