module Schools
  module RegisterMentorWizard
    class RegistrationStore
      class Presenter
        def initialize(registration_store:)
          @registration_store = registration_store
        end

        def full_name
          (registration_store.corrected_name.presence || trs_full_name)&.strip
        end

        def formatted_date_of_birth
          registration_store.trs_date_of_birth.to_date&.to_formatted_s(:govuk)
        end

        def trs_full_name
          [registration_store.trs_first_name, registration_store.trs_last_name].compact.join(" ").presence
        end

      private

        attr_reader :registration_store
      end
    end
  end
end
