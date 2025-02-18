module Schools
  module Validation
    class TeacherReferenceNumber
      MIN_UNPADDED_TRN_LENGTH = 5
      PADDED_TRN_LENGTH = 7

      attr_reader :trn, :error_message

      def initialize(trn)
        @trn = trn
        @error_message = nil
      end

      def formatted_trn
        @formatted_trn ||= extract_trn_value
      end

      def valid?
        formatted_trn.present?
      end

    private

      def extract_trn_value
        @error_message = "Enter the teacher reference number (TRN)" and return if trn.blank?

        # remove any characters that are not digits
        only_digits = trn.to_s.gsub(/[^\d]/, "")

        @error_message = "Teacher reference number must include at least 5 digits" and return if only_digits.blank?
        @error_message = "Teacher reference number must include at least 5 digits" and return if only_digits.length < MIN_UNPADDED_TRN_LENGTH
        @error_message = "Teacher reference number cannot include more than 7 digits" and return if only_digits.length > PADDED_TRN_LENGTH

        only_digits.rjust(PADDED_TRN_LENGTH, "0")
      end
    end
  end
end
