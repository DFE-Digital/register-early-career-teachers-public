module Schools
  module Validation
    class TeacherReferenceNumber
      MIN_UNPADDED_TRN_LENGTH = 5
      PADDED_TRN_LENGTH = 7

      attr_reader :trn, :error_message, :formatted_trn

      def initialize(trn)
        @trn = trn
        @error_message = nil
        @formatted_trn ||= format_trn
      end

      def valid?
        @error_message.nil?
      end

    private

      def format_trn
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
