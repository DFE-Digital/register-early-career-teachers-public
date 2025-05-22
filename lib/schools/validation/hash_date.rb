module Schools
  module Validation
    class HashDate
      DATE_MISSING_MESSAGE = "Enter a date".freeze
      INVALID_FORMAT_MESSAGE = "Enter the date in the correct format, for example 30 06 2001".freeze

      attr_reader :date_as_hash, :error_message

      # Expects value with the format { 1 => year, 2 => month, 3 => day } or a date string or a Date instance
      def initialize(value)
        @date_as_hash = value.is_a?(Hash) ? integerize_keys!(value) : convert_to_hash(value&.to_date)
      end

      def valid?
        @error_message = validate
        error_message.blank?
      end

    private

      def integerize_keys!(hash)
        hash.transform_keys(&:to_i)
      end

      def convert_to_hash(date)
        { 3 => date.day, 2 => date.month, 1 => date.year } if date
      end

      def value_as_date
        @value_as_date ||= Date.new(*date_as_hash.values_at(1, 2, 3).map(&:to_i))
      end

      def date_missing?
        date_as_hash.nil?
      end

      def extra_validation_error_message = nil

      def invalid_date?
        return true if year_zero?

        value_as_date
        false
      rescue ArgumentError
        true
      end

      def validate
        return self.class::DATE_MISSING_MESSAGE if date_missing?
        return self.class::INVALID_FORMAT_MESSAGE if invalid_date?

        extra_validation_error_message
      end

      def year_zero?
        date_as_hash[1].to_i.zero?
      end
    end
  end
end
