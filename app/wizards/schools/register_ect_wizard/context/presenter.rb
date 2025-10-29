module Schools
  module RegisterECTWizard
    class Context
      class Presenter
        def initialize(context:)
          @context = context
        end

        def full_name
          (@context.corrected_name.presence || @context.trs_full_name)&.strip
        end
      end
    end
  end
end
