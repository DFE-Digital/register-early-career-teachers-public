module Schools
  module RegisterECTWizard
    # This class is a decorator for the SessionRepository
    class ECT < SimpleDelegator
      def active_at_school?(urn)
        active_record_at_school(urn).present?
      end

      def active_record_at_school(urn)
        @active_record_at_school ||= ECTAtSchoolPeriods::Search.new.ect_periods(trn:, urn:).ongoing.last
      end

      def appropriate_body
        @appropriate_body ||= AppropriateBody.find_by_id(appropriate_body_id)
      end

      # appropriate_body_name
      delegate :name, to: :appropriate_body, prefix: true, allow_nil: true

      def cant_use_email?
        Schools::TeacherEmail.new(email:, trn:).is_currently_used?
      end

      def ect_at_school_period
        @ect_at_school_period ||= ECTAtSchoolPeriod.find_by_id(ect_at_school_period_id)
      end

      def formatted_working_pattern
        working_pattern.humanize
      end

      def full_name
        (corrected_name.presence || trs_full_name)&.strip
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
        prohibited_from_teaching == true
      end

      def registered?
        ect_at_school_period_id.present?
      end

      def was_school_led?
        previous_training_programme == 'school_led'
      end

      def induction_start_date
        first_induction_period&.started_on
      end

      def lead_provider
        @lead_provider ||= LeadProvider.find(lead_provider_id) if lead_provider_id
      end

      # lead_provider_name
      delegate :name, to: :lead_provider, prefix: true, allow_nil: true

      def matches_trs_dob?
        return false if [date_of_birth, trs_date_of_birth].any?(&:blank?)

        trs_date_of_birth.to_date == date_of_birth.to_date
      end

      def lead_providers_within_contract_period
        return [] unless contract_start_date

        @lead_providers_within_contract_period ||= LeadProviders::Active.in_contract_period(contract_start_date).select(:id, :name)
      end

      def contract_start_date
        ContractPeriod.containing_date(start_date&.to_date)
      end

      def previously_registered?
        previous_ect_at_school_period.present?
      end

      def previous_appropriate_body_name
        previous_appropriate_body&.name
      end

      def previous_delivery_partner_name
        previous_delivery_partner&.name
      end

      def previous_lead_provider_name
        previous_lead_provider&.name
      end

      def previous_provider_led?
        previous_training_period&.provider_led_training_programme?
      end

      def previous_school
        previous_ect_at_school_period&.school
      end

      # previous_school_name
      delegate :name, to: :previous_school, prefix: true, allow_nil: true

      def previous_training_programme
        previous_training_period&.training_programme
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

      def previous_ect_at_school_period
        @previous_ect_at_school_period ||= ECTAtSchoolPeriods::Search
          .new(order: :started_on)
          .ect_periods(trn:)
          .last
      end

      def lead_provider_has_confirmed_partnership_for_contract_period?(school)
        return false unless previous_lead_provider && contract_start_date && school

        SchoolPartnerships::Search
          .new(school:, lead_provider: previous_lead_provider, contract_period: contract_start_date)
          .exists?
      end

      def previous_eoi_lead_provider_name
        return unless previous_training_period&.expression_of_interest

        previous_training_period&.expression_of_interest&.lead_provider&.name
      end

    private

      def first_induction_period
        ordered_induction_periods.first
      end

      def ordered_induction_periods
        @ordered_induction_periods ||= InductionPeriods::Search
          .new(order: :started_on)
          .induction_periods(trn:)
      end

      def previous_appropriate_body
        previous_induction_period&.appropriate_body
      end

      def previous_delivery_partner
        previous_training_period&.delivery_partner
      end

      def previous_induction_period
        ordered_induction_periods.last
      end

      def previous_lead_provider
        previous_training_period&.lead_provider
      end

      def previous_training_period
        return unless previous_ect_at_school_period

        @previous_training_period ||= TrainingPeriods::Search
          .new(order: :started_on)
          .training_periods(ect_id: previous_ect_at_school_period.id)
          .last
      end
    end
  end
end
