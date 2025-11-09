module Schools
  module RegisterECTWizard
    # This class is a decorator for the SessionRepository
    class RegistrationStore < SimpleDelegator
      def initialize(store)
        super(store)
        @queries   = RegistrationStore::Queries.new(registration_store: self)
        @presenter = RegistrationStore::Presenter.new(registration_store: self)
        @previous_registration = RegistrationStore::PreviousRegistration.new(registration_store: self, queries:)
        @status = RegistrationStore::Status.new(registration_store: self, queries:)
      end

      delegate :ect_at_school_period,
               :active_record_at_school,
               :appropriate_body,
               :lead_providers_within_contract_period,
               :contract_start_date,
               :lead_provider,
               :previous_ect_at_school_period,
               to: :queries

      delegate :full_name,
               :formatted_working_pattern,
               :formatted_date_of_birth,
               to: :presenter

      delegate :previous_school,
               :previous_school_name,
               :previous_lead_provider,
               :previous_lead_provider_name,
               :previous_delivery_partner_name,
               :previous_appropriate_body_name,
               :previous_training_programme,
               :previous_provider_led?,
               :previous_eoi_lead_provider_name,
               to: :previous_registration

      delegate :email_taken?,
               :in_trs?,
               :induction_completed?,
               :induction_exempt?,
               :induction_failed?,
               :prohibited_from_teaching?,
               :registered?,
               :was_school_led?,
               :matches_trs_dob?,
               :provider_led?,
               :school_led?,
               :lead_provider_has_confirmed_partnership_for_contract_period?,
               to: :status

      # appropriate_body_name
      delegate :name, to: :appropriate_body, prefix: true, allow_nil: true

      # lead_provider_name
      delegate :name, to: :lead_provider, prefix: true, allow_nil: true

      def register!(school, author:, store: nil)
        Schools::RegisterECT.new(school_reported_appropriate_body: appropriate_body,
                                 corrected_name:,
                                 email:,
                                 lead_provider: (lead_provider if provider_led?),
                                 training_programme:,
                                 school:,
                                 started_on: Date.parse(start_date),
                                 trn:,
                                 trs_first_name:,
                                 trs_last_name:,
                                 working_pattern:,
                                 author:,
                                 store:)
                            .register!
      end

      def active_at_school?(urn)
        active_record_at_school(urn).present?
      end

      def induction_start_date
        queries.first_induction_period&.started_on
      end

      def previously_registered?
        previous_registration.present?
      end

      def trs_full_name
        Teachers::Name.new(self).full_name_in_trs
      end

      def normalized_start_date
        return store[:start_date_as_date] if respond_to?(:store) && store[:start_date_as_date].present?

        case start_date
        when Date   then start_date
        when String then Date.parse(start_date)
        when Hash   then Schools::Validation::ECTStartDate.new(date_as_hash: start_date).value_as_date
        end
      end

    private

      attr_reader :queries, :previous_registration, :presenter, :status
    end
  end
end
