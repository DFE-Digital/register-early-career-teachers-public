module Schools
  module RegisterECTWizard
    class RegistrationStore
      class Status
        def initialize(registration_store:, queries:)
          @registration_store = registration_store
          @queries = queries
        end

        def email_taken?
          Schools::TeacherEmail.new(email: registration_store.email, trn: registration_store.trn).is_currently_used?
        end

        def in_trs?
          registration_store.trs_first_name.present?
        end

        def induction_completed?
          registration_store.trs_induction_status == "Passed"
        end

        def induction_exempt?
          registration_store.trs_induction_status == "Exempt"
        end

        def induction_failed?
          registration_store.trs_induction_status == "Failed"
        end

        def prohibited_from_teaching?
          registration_store.trs_prohibited_from_teaching == true
        end

        def registered?
          registration_store.ect_at_school_period_id.present?
        end

        def was_school_led?
          registration_store.previous_training_programme == "school_led"
        end

        def matches_trs_dob?
          return false if [registration_store.date_of_birth, registration_store.trs_date_of_birth].any?(&:blank?)

          registration_store.trs_date_of_birth.to_date == registration_store.date_of_birth.to_date
        end

        def provider_led?
          registration_store.training_programme == "provider_led"
        end

        def school_led?
          registration_store.training_programme == "school_led"
        end

        def lead_provider_has_confirmed_partnership_for_contract_period?(school)
          queries.lead_provider_partnership_for_contract_period(school:).exists?
        end

      private

        attr_reader :registration_store, :queries
      end
    end
  end
end
