module Schools
  module Validation
    class HashDate
      DATE_MISSING_MESSAGE = "Enter a date".freeze
      INVALID_FORMAT_MESSAGE = "Enter the date in the correct format, for example 12 03 1998".freeze # TODO: Dates before 1999 are not supported so change this content?
      NEGATIVE_INTEGER_MESSAGE = "Enter positive numbers only".freeze # Date.new will still accept these creating strange results

      attr_reader :date_as_hash, :error_message

      # Expects value with the format { 1 => year, 2 => month, 3 => day } or a date string or a Date instance
      def initialize(value)
        @date_as_hash = value.is_a?(Hash) ? value : convert_to_hash(value&.to_date)
      end

      def valid?
        @error_message = validate
        error_message.blank?
      end

    private

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
        value_as_date
        false
      rescue ArgumentError
        true
      end

      def negative_date?
        date_as_hash.values_at(1, 2, 3).map(&:to_i).any?(&:negative?)
      end

      def validate
        return self.class::DATE_MISSING_MESSAGE if date_missing?
        return self.class::INVALID_FORMAT_MESSAGE if invalid_date?
        return self.class::NEGATIVE_INTEGER_MESSAGE if negative_date?

        extra_validation_error_message
      end
    end
  end
end
