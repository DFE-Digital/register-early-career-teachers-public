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

      def induction_completed?
        trs_induction_status == 'Passed'
      end

      def induction_exempt?
        trs_induction_status == 'Exempt'
      end

      def induction_failed?
        trs_induction_status == 'Failed'
      end

      def in_trs?
        trs_first_name.present?
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

      # Extract into their own SO when this logic becomes dependant of the ECT being assigned
      def possible_lead_providers
        @possible_lead_providers ||= LeadProvider.select(:id, :name).all
      end

      def provider_led?
        programme_type == 'provider_led'
      end

      def register!(school, author:)
        Schools::RegisterECT.new(school_reported_appropriate_body: appropriate_body,
                                 corrected_name:,
                                 email:,
                                 lead_provider: (lead_provider if provider_led?),
                                 programme_type:,
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
        programme_type == 'school_led'
      end

      def trs_full_name
        Teachers::Name.new(self).full_name_in_trs
      end
    end
  end
end
