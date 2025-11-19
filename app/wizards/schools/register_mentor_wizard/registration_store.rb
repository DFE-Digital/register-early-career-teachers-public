# Steps in Schools::RegisterMentorWizard will have a Schools::RegisterMentorWizard::RegistrationStore instance
# available rather than the wizard store directly.
# The aim of this class is to encapsulate and provide Mentor logic instead of spreading it across the various steps.
#
# This class will depend so much on the multiple data saved in the wizard.store by the steps during the journey
# that has been built on top of it by inheriting from Ruby SimpleDelegator class.
module Schools
  module RegisterMentorWizard
    class RegistrationStore < SimpleDelegator
      def initialize(store)
        super(store)
        @presenter = RegistrationStore::Presenter.new(registration_store: self)
        @queries   = RegistrationStore::Queries.new(registration_store: self)
        @status    = RegistrationStore::Status.new(registration_store: self, queries:)
      end

      delegate :full_name,
               :formatted_date_of_birth,
               :trs_full_name,
               to: :presenter

      delegate :active_record_at_school,
               :school,
               :lead_provider,
               :lead_providers_within_contract_period,
               :contract_period,
               :mentor_at_school_periods,
               :previous_school_mentor_at_school_periods,
               :previous_training_period,
               :previous_confirmed_training_period,
               :latest_registration_choice,
               :ect,
               :ect_training_service,
               to: :queries

      delegate :email_taken?,
               :corrected_name?,
               :in_trs?,
               :matches_trs_dob?,
               :eligible_for_funding?,
               :became_ineligible_for_funding?,
               :prohibited_from_teaching?,
               :previously_registered_as_mentor?,
               :currently_mentor_at_another_school?,
               :previous_school_closed_mentor_at_school_periods?,
               :previous_provider_led?,
               :mentorship_status,
               :provider_led_ect?,
               :ect_lead_provider_invalid?,
               :mentoring_at_new_school_only?,
               to: :status

      delegate :expression_of_interest?, to: :ect_training_service

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

      def active_at_school?
        active_record_at_school.present?
      end

      # The form submits a symbol (:yes or :no), but Rails stores it as a string ('yes'/'no').
      def finish_existing_at_school_periods
        mentoring_at_new_school_only?
      end

      def ect_lead_provider
        ect_training_service.lead_provider_via_school_partnership_or_eoi
      end

    private

      attr_reader :queries, :status, :presenter
    end
  end
end
