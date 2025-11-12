# Steps in Schools::RegisterMentorWizard will have a Schools::RegisterMentor::Mentor instance
# available rather than the wizard store directly.
# The aim of this class is to encapsulate and provide Mentor logic instead of spreading it across the various steps.
#
# This class will depend so much on the multiple data saved in the wizard.store by the steps during the journey
# that has been built on top of it by inheriting from Ruby SimpleDelegator class.
module Schools
  module RegisterMentorWizard
    class Mentor < SimpleDelegator
      def active_at_school?
        active_record_at_school.present?
      end

      def active_record_at_school
        @active_record_at_school ||= MentorAtSchoolPeriods::Search.new.mentor_periods(trn:, urn: school_urn).ongoing.last
      end

      def email_taken?
        Schools::TeacherEmail.new(email:, trn:).is_currently_used?
      end

      def corrected_name?
        corrected_name.present?
      end

      def full_name
        @full_name ||= (corrected_name || trs_full_name).strip
      end

      def govuk_date_of_birth
        trs_date_of_birth.to_date&.to_formatted_s(:govuk)
      end

      def in_trs?
        trs_first_name.present?
      end

      def matches_trs_dob?
        return false if [date_of_birth, trs_date_of_birth].any?(&:blank?)

        trs_date_of_birth.to_date == date_of_birth.to_date
      end

      def funding_available?
        Teachers::MentorFundingEligibility.new(trn:).eligible?
      end

      def register!(author:)
        Schools::RegisterMentor.new(trs_first_name:,
                                    trs_last_name:,
                                    corrected_name:,
                                    trn:,
                                    school_urn:,
                                    email:,
                                    author:,
                                    started_on:,
                                    finish_existing_at_school_periods:,
                                    lead_provider:)
                               .register!
                               .tap { self.registered = true }
      end

      def school
        @school ||= School.find_by_urn(school_urn)
      end

      def trs_full_name
        @trs_full_name ||= [trs_first_name, trs_last_name].join(" ")
      end

      def prohibited_from_teaching?
        trs_prohibited_from_teaching == true
      end

      def ect
        @ect ||= ECTAtSchoolPeriod.find(store["ect_id"]) if store["ect_id"].present?
      end

      def ect_lead_provider_invalid?
        return false unless ect_lead_provider

        !LeadProviders::Active.new(ect_lead_provider).active_in_contract_period?(contract_period)
      end

      def lead_provider
        @lead_provider ||= LeadProvider.find(lead_provider_id) if lead_provider_id
      end

      # The form submits a symbol (:yes or :no), but Rails stores it as a string ('yes'/'no').
      def finish_existing_at_school_periods
        mentoring_at_new_school_only == "yes"
      end

      def latest_registration_choice
        @latest_registration_choice ||= MentorAtSchoolPeriods::LatestRegistrationChoices.new(trn:)
      end

      def previous_training_period
        @previous_training_period ||= latest_registration_choice.confirmed_training_period
      end

      def previous_provider_led?
        previous_training_period&.training_programme == "provider_led"
      end

      def lead_providers_within_contract_period
        return [] unless contract_period

        @lead_providers_within_contract_period ||= LeadProviders::Active.in_contract_period(contract_period).select(:id, :name)
      end

      def contract_period
        ContractPeriod.containing_date(started_on&.to_date || Date.current)
      end

      # Does mentor have any previous mentor_at_school_periods (open or closed)?
      def previously_registered_as_mentor?
        mentor_at_school_periods.exists?
      end

      # Does mentor have an open mentor_at_school_period at another school?
      def currently_mentor_at_another_school?
        previous_school_mentor_at_school_periods.exists?
      end

      def previous_school_mentor_at_school_periods
        finishes_in_the_future_scope = ::MentorAtSchoolPeriod.finished_on_or_after(start_date)
        mentor_at_school_periods.where.not(school:).ongoing.or(finishes_in_the_future_scope)
      end

      def mentorship_status
        if mentor_at_school_periods.any?(&:ongoing?)
          :currently_a_mentor
        elsif mentor_at_school_periods.any?
          :previously_a_mentor
        else
          raise 'Unexpected state: no mentor_at_school_periods found for previously registered mentor'
        end
      end

      # Is mentor being assigned to a provider-led ECT?
      def provider_led_ect?
        ect&.provider_led_training_programme?
      end

      # Does that mentor have a mentor_became_ineligible_for_funding_on?
      def became_ineligible_for_funding?
        ::Teachers::MentorFundingEligibility.new(trn:).ineligible?
      end

      def eligible_for_funding?
        ::Teachers::MentorFundingEligibility.new(trn:).eligible?
      end

      def ect_lead_provider
        ect_training_service.lead_provider_via_school_partnership_or_eoi
      end

      delegate :expression_of_interest?, to: :ect_training_service

      def mentoring_at_new_school_only?
        store.fetch("mentoring_at_new_school_only", "yes") == "yes"
      end

    private

      def mentor_at_school_periods
        ::MentorAtSchoolPeriods::Search.new.mentor_periods(trn:)
      end

      def ect_training_service
        @ect_training_service ||= ECTAtSchoolPeriods::CurrentTraining.new(ect)
      end

      # The wizard store object where we delegate the rest of methods
      def wizard_store
        __getobj__
      end
    end
  end
end
