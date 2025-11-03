module Schools
  module RegisterECTWizard
    # This class is a decorator for the SessionRepository
    class Context < SimpleDelegator
      def initialize(store)
        super(store)
        @queries   = Context::Queries.new(context: self)
        @presenter = Context::Presenter.new(context: self)
        @previous_registration = Context::PreviousRegistration.new(context: self, queries: @queries)
        @status = Context::Status.new(context: self, queries: @queries)
      end

      delegate :full_name,
               :formatted_working_pattern,
               :govuk_date_of_birth,
               to: :@presenter

      delegate :ect_at_school_period, to: :queries

      def active_at_school?(urn)
        active_record_at_school(urn).present?
      end

      delegate :active_record_at_school, :appropriate_body, to: :queries

      # appropriate_body_name
      delegate :name, to: :appropriate_body, prefix: true, allow_nil: true

      delegate :cant_use_email?,
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
               to: :@status

      def induction_start_date
        queries.first_induction_period&.started_on
      end

      delegate :lead_provider, to: :queries

      # lead_provider_name
      delegate :name, to: :lead_provider, prefix: true, allow_nil: true

      delegate :lead_providers_within_contract_period, :contract_start_date, to: :queries

      def previously_registered?
        previous_registration.present?
      end

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

      def register!(school, author:)
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
                                 author:)
                            .register!
      end

      def trs_full_name
        Teachers::Name.new(self).full_name_in_trs
      end

      delegate :previous_ect_at_school_period, to: :queries
      delegate :lead_provider_has_confirmed_partnership_for_contract_period?, to: :@status

    private

      attr_reader :queries, :previous_registration
    end
  end
end
