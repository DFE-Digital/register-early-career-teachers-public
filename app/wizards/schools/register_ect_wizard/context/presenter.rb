module Schools
  module RegisterECTWizard
    class Context
      class Presenter
        def initialize(context:)
          @context = context
        end

        def full_name
          (context.corrected_name.presence || context.trs_full_name)&.strip
        end

        def formatted_working_pattern
          context.working_pattern&.humanize
        end

        def govuk_date_of_birth
          context.trs_date_of_birth&.to_date&.to_formatted_s(:govuk)
        end

      private

        attr_reader :context
      end
    end
  end
end
