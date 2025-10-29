module Schools
  module RegisterECTWizard
    class Context
      class Status
        def initialize(context:, queries:)
          @context = context
          @queries = queries
        end
      end
    end
  end
end
