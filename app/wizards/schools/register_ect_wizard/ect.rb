module Schools
  module RegisterECTWizard
    # This class is a decorator for the SessionRepository
    class ECT < SimpleDelegator
      def cant_use_email?
        Schools::TeacherEmail.new(email:, trn:).is_currently_used?
      end

      def full_name
        (corrected_name.presence || trs_full_name)&.strip
      end

      def govuk_date_of_birth
        trs_date_of_birth&.to_date&.to_formatted_s(:govuk)
      end

      def ect_at_school_period
        @ect_at_school_period ||= ECTAtSchoolPeriod.find_by_id(ect_at_school_period_id)
      end

      def in_trs?
        trs_first_name.present?
      end

      def matches_trs_dob?
        return false if [date_of_birth, trs_date_of_birth].any?(&:blank?)

        trs_date_of_birth.to_date == date_of_birth.to_date
      end

      def induction_completed?
        trs_induction_status == 'Pass'
      end

      def induction_exempt?
        trs_induction_status == 'Exempt'
      end

      def teaching_induction_panel?
        appropriate_body_type == 'teaching_induction_panel'
      end

      def provider_led?
        programme_type == 'provider_led'
      end

      def school_led?
        programme_type == 'school_led'
      end

      def formatted_programme_type
        programme_type.capitalize.dasherize
      end

      def formatted_working_pattern
        working_pattern.humanize
      end

      def formatted_appropriate_body_name
        teaching_induction_panel? ? 'Independent Schools Teacher Induction Panel (ISTIP)' : appropriate_body.name
      end

      def formatted_lead_provider_name
        lead_provider&.name
      end

      def register!(school)
        Schools::RegisterECT.new(trs_first_name:,
                                 trs_last_name:,
                                 corrected_name:,
                                 trn:,
                                 school:,
                                 started_on: Date.parse(start_date),
                                 working_pattern:,
                                 email:,
                                 appropriate_body:,
                                 lead_provider:,
                                 programme_type:).register!
      end

      def active_at_school?(school:)
        ECTAtSchoolPeriods::Search.new.exists?(school_id: school.id, trn:)
      end

      def appropriate_body
        AppropriateBody.find_by_id(appropriate_body_id)
      end

      def lead_provider
        LeadProvider.find(lead_provider_id) if provider_led?
      end

      def trs_full_name
        Teachers::Name.new(self).full_name_in_trs
      end
    end
  end
end
