module Schools
  module RegisterECTWizard
    class RegistrationSession
      class Status
        def initialize(context:, queries:)
          @context = context
          @queries = queries
        end

        def cant_use_email?
          Schools::TeacherEmail.new(email: context.email, trn: context.trn).is_currently_used?
        end

        def in_trs?
          context.trs_first_name.present?
        end

        def induction_completed?
          context.trs_induction_status == 'Passed'
        end

        def induction_exempt?
          context.trs_induction_status == 'Exempt'
        end

        def induction_failed?
          context.trs_induction_status == 'Failed'
        end

        def prohibited_from_teaching?
          context.trs_prohibited_from_teaching == true
        end

        def registered?
          context.ect_at_school_period_id.present?
        end

        def was_school_led?
          context.previous_training_programme == 'school_led'
        end

        def matches_trs_dob?
          return false if [context.date_of_birth, context.trs_date_of_birth].any?(&:blank?)

          context.trs_date_of_birth.to_date == context.date_of_birth.to_date
        end

        def provider_led?
          context.training_programme == 'provider_led'
        end

        def school_led?
          context.training_programme == 'school_led'
        end

        def lead_provider_has_confirmed_partnership_for_contract_period?(school)
          previous_lead_provider = queries.previous_lead_provider
          contract_period = context.contract_start_date

          return false unless previous_lead_provider && contract_period && school

          SchoolPartnerships::Search
            .new(school:, lead_provider: previous_lead_provider, contract_period:)
            .exists?
        end

      private

        attr_reader :context, :queries
      end
    end
  end
end
