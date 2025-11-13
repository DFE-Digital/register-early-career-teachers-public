module Schools
  module RegisterECTWizard
    class RegistrationStore
      class Presenter
        def initialize(registration_store:)
          @registration_store = registration_store
        end

        def full_name
          (registration_store.corrected_name.presence || registration_store.trs_full_name)&.strip
        end

        def formatted_working_pattern
          registration_store.working_pattern&.humanize
        end

        def formatted_date_of_birth
          registration_store.trs_date_of_birth&.to_date&.to_formatted_s(:govuk)
        end

      private

        attr_reader :registration_store
      end
    end
  end
end
