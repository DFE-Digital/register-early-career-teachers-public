module Schools
  module Validation
    class Date
      DATE_MISSING_MESSAGE = "Enter a date".freeze
      INVALID_FORMAT_MESSAGE = "Enter the date in the correct format, for example 12 03 1998".freeze

      attr_reader :date_as_hash, :error_message

      # Expects value with the format { 1 => year, 2 => month, 3 => day } or a date string or a Date instance
      def initialize(value)
        @date_as_hash = value.is_a?(Hash) ? value : convert_to_hash(value&.to_date)
      end

      def valid?
        validate
        error_message.blank?
      end

    private

      def convert_to_hash(date)
        { 3 => date.day, 2 => date.month, 1 => date.year } if date
      end

      def date
        day = date_as_hash[3].to_i
        month = date_as_hash[2].to_i
        year = date_as_hash[1].to_i

        @date ||= ::Date.new(year, month, day)
      end

      def date_missing?
        date_as_hash.nil?
      end

      def extra_validation_error_message = nil

      def invalid_date?
        date
        false
      rescue ArgumentError
        true
      end

      def validate
        return @error_message = self.class::DATE_MISSING_MESSAGE if date_missing?
        return @error_message = self.class::INVALID_FORMAT_MESSAGE if invalid_date?

        @error_message = extra_validation_error_message
      end
    end
  end
end
