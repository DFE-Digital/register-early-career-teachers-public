module Schools
  module RegisterECTWizard
    class RegistrationSession
      class Presenter
        def initialize(registration_session:)
          @registration_session = registration_session
        end

        def full_name
          (registration_session.corrected_name.presence || registration_session.trs_full_name)&.strip
        end

        def formatted_working_pattern
          registration_session.working_pattern&.humanize
        end

        def formatted_date_of_birth
          registration_session.trs_date_of_birth&.to_date&.to_formatted_s(:govuk)
        end

      private

        attr_reader :registration_session
      end
    end
  end
end
