module Schools
  module RegisterMentorWizard
    class RegistrationSession
      class Presenter
        def initialize(registration_session:)
          @registration_session = registration_session
        end

        def full_name
          (registration_session.corrected_name.presence || trs_full_name)&.strip
        end

        def formatted_date_of_birth
          registration_session.trs_date_of_birth.to_date&.to_formatted_s(:govuk)
        end

        def trs_full_name
          [registration_session.trs_first_name, registration_session.trs_last_name].compact.join(" ").presence
        end

      private

        attr_reader :registration_session
      end
    end
  end
end
