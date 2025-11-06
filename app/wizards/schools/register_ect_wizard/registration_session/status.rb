module Schools
  module RegisterECTWizard
    class RegistrationSession
      class Status
        def initialize(registration_session:, queries:)
          @registration_session = registration_session
          @queries = queries
        end

        def email_taken?
          Schools::TeacherEmail.new(email: registration_session.email, trn: registration_session.trn).is_currently_used?
        end

        def in_trs?
          registration_session.trs_first_name.present?
        end

        def induction_completed?
          registration_session.trs_induction_status == 'Passed'
        end

        def induction_exempt?
          registration_session.trs_induction_status == 'Exempt'
        end

        def induction_failed?
          registration_session.trs_induction_status == 'Failed'
        end

        def prohibited_from_teaching?
          registration_session.trs_prohibited_from_teaching == true
        end

        def registered?
          registration_session.ect_at_school_period_id.present?
        end

        def was_school_led?
          registration_session.previous_training_programme == 'school_led'
        end

        def matches_trs_dob?
          return false if [registration_session.date_of_birth, registration_session.trs_date_of_birth].any?(&:blank?)

          registration_session.trs_date_of_birth.to_date == registration_session.date_of_birth.to_date
        end

        def provider_led?
          registration_session.training_programme == 'provider_led'
        end

        def school_led?
          registration_session.training_programme == 'school_led'
        end

        def lead_provider_has_confirmed_partnership_for_contract_period?(school)
          previous_lead_provider = queries.previous_lead_provider
          contract_period = registration_session.contract_start_date

          return false unless previous_lead_provider && contract_period && school

          SchoolPartnerships::Search
            .new(school:, lead_provider: previous_lead_provider, contract_period:)
            .exists?
        end

      private

        attr_reader :registration_session, :queries
      end
    end
  end
end
