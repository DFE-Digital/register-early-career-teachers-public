module Schools
  module RegisterECTWizard
    # This class is a decorator for the SessionRepository
    class Context < SimpleDelegator
      def initialize(store)
        super(store)
        @queries   = Context::Queries.new(context: self)
        @presenter = Context::Presenter.new(context: self)
        @status    = Context::Status.new(context: self, queries: @queries)
      end

      delegate :full_name, to: :@presenter

      delegate :ect_at_school_period, to: :queries

      def active_at_school?(urn)
        active_record_at_school(urn).present?
      end

      delegate :active_record_at_school, :appropriate_body, to: :queries

      # appropriate_body_name
      delegate :name, to: :appropriate_body, prefix: true, allow_nil: true

      def cant_use_email?
        Schools::TeacherEmail.new(email:, trn:).is_currently_used?
      end

      def formatted_working_pattern
        working_pattern.humanize
      end

      def govuk_date_of_birth
        trs_date_of_birth&.to_date&.to_formatted_s(:govuk)
      end

      def in_trs?
        trs_first_name.present?
      end

      def induction_completed?
        trs_induction_status == 'Passed'
      end

      def induction_exempt?
        trs_induction_status == 'Exempt'
      end

      def induction_failed?
        trs_induction_status == 'Failed'
      end

      def prohibited_from_teaching?
        trs_prohibited_from_teaching == true
      end

      def registered?
        ect_at_school_period_id.present?
      end

      def was_school_led?
        previous_training_programme == 'school_led'
      end

      def induction_start_date
        queries.first_induction_period&.started_on
      end

      delegate :lead_provider, to: :queries

      # lead_provider_name
      delegate :name, to: :lead_provider, prefix: true, allow_nil: true

      def matches_trs_dob?
        return false if [date_of_birth, trs_date_of_birth].any?(&:blank?)

        trs_date_of_birth.to_date == date_of_birth.to_date
      end

      delegate :lead_providers_within_contract_period, :contract_start_date, to: :queries

      def previously_registered?
        previous_ect_at_school_period.present?
      end

      def previous_appropriate_body_name
        queries.previous_appropriate_body&.name
      end

      def previous_delivery_partner_name
        queries.previous_delivery_partner&.name
      end

      def previous_lead_provider_name
        queries.previous_lead_provider&.name
      end

      def previous_provider_led?
        queries.previous_training_period&.provider_led_training_programme?
      end

      delegate :previous_school, to: :queries

      # previous_school_name
      delegate :name, to: :previous_school, prefix: true, allow_nil: true

      def previous_training_programme
        queries.previous_training_period&.training_programme
      end

      def provider_led?
        training_programme == 'provider_led'
      end

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

      def school_led?
        training_programme == 'school_led'
      end

      def trs_full_name
        Teachers::Name.new(self).full_name_in_trs
      end

      delegate :previous_ect_at_school_period, to: :queries

      def lead_provider_has_confirmed_partnership_for_contract_period?(school)
        return false unless queries.previous_lead_provider && contract_start_date && school

        SchoolPartnerships::Search
          .new(school:, lead_provider: queries.previous_lead_provider, contract_period: contract_start_date)
          .exists?
      end

      def previous_eoi_lead_provider_name
        previous_training_period = queries.previous_training_period
        return unless previous_training_period&.expression_of_interest

        previous_training_period.expression_of_interest&.lead_provider&.name
      end

    private

      attr_reader :queries
    end
  end
end
