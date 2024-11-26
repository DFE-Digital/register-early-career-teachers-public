module Schools
  module RegisterECT
    class ECT < SimpleDelegator
      def full_name
        [trs_first_name, trs_last_name].join(" ").strip
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

      def matches_trs_national_insurance_number?
        return false if [national_insurance_number, trs_national_insurance_number].any?(&:blank?)

        trs_national_insurance_number == national_insurance_number
      end

      def induction_completed?
        trs_induction_completed?
      end

      def induction_exempt?
        trs_induction_exempt?
      end
    end
  end
end
