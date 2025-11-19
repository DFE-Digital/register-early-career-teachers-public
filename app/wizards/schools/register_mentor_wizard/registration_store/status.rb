module Schools
  module RegisterMentorWizard
    class RegistrationStore
      class Status
        def initialize(registration_store:, queries:)
          @registration_store = registration_store
          @queries = queries
        end

        class MentorStatusError < StandardError; end

        def email_taken?
          Schools::TeacherEmail.new(email: registration_store.email, trn: registration_store.trn).is_currently_used?
        end

        def corrected_name?
          registration_store.corrected_name.present?
        end

        def in_trs?
          registration_store.trs_first_name.present?
        end

        def matches_trs_dob?
          return false if [registration_store.date_of_birth, registration_store.trs_date_of_birth].any?(&:blank?)

          registration_store.trs_date_of_birth.to_date == registration_store.date_of_birth.to_date
        end

        def eligible_for_funding?
          mentor_funding_eligibility.eligible?
        end

        def became_ineligible_for_funding?
          mentor_funding_eligibility.ineligible?
        end

        def prohibited_from_teaching?
          registration_store.trs_prohibited_from_teaching == true
        end

        def previously_registered_as_mentor?
          queries.mentor_at_school_periods.exists?
        end

        def currently_mentor_at_another_school?
          queries.previous_school_mentor_at_school_periods.exists?
        end

        def previous_school_closed_mentor_at_school_periods?
          queries.previous_school_mentor_at_school_periods.where.not(finished_on: nil).exists?
        end

        def mentorship_status
          mentor_at_school_periods = queries.mentor_at_school_periods

          if mentor_at_school_periods.any?(&:ongoing?)
            :currently_a_mentor
          elsif mentor_at_school_periods.any?
            :previously_a_mentor
          else
            raise MentorStatusError, "No mentor_at_school_periods found for a previously registered mentor"
          end
        end

        def provider_led_ect?
          queries.ect&.provider_led_training_programme?
        end

        def ect_lead_provider_invalid?
          return false unless registration_store.ect_lead_provider

          !LeadProviders::Active.new(registration_store.ect_lead_provider).active_in_contract_period?(queries.contract_period)
        end

        def mentoring_at_new_school_only?
          registration_store.store.fetch("mentoring_at_new_school_only", "yes") == "yes"
        end

      private

        attr_reader :registration_store, :queries

        def mentor_funding_eligibility
          @mentor_funding_eligibility ||= Teachers::MentorFundingEligibility.new(trn: registration_store.trn)
        end
      end
    end
  end
end
