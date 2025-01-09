module Schools
  module RegisterECTWizard
    class ECT < SimpleDelegator
      # This class is a decorator for the SessionRepository
      def full_name
        corrected_name.presence || [trs_first_name, trs_last_name].join(" ").strip
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

      def formatted_programme_type
        programme_type.capitalize.dasherize
      end

      def register!(school)
        Schools::RegisterECT.new(first_name: trs_first_name,
                                 last_name: trs_last_name,
                                 corrected_name:,
                                 trn:,
                                 school:,
                                 started_on: Date.parse(start_date),
                                 working_pattern:)
                               .register_teacher!
      end
    end
  end
end
