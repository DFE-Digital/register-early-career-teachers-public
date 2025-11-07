module Schools
  module Validation
    class HashDate
      DATE_MISSING_MESSAGE = "Enter a date"
      INVALID_FORMAT_MESSAGE = "Enter the date in the correct format, for example 30 06 2001"

      attr_reader :date_as_hash, :error_message

      # Expects value with the format { 1 => year, 2 => month, 3 => day } or a date string or a Date instance.
      # Updated to also accept Rails-style hashes ({ "day" => "1", "month" => "9", "year" => "2025" })
      def initialize(value = nil, date_as_hash: nil)
        input = date_as_hash.nil? ? value : date_as_hash

        @date_as_hash =
          if input.is_a?(Hash) || input.is_a?(ActionController::Parameters)
            normalize_date_hash(input)
          else
            convert_to_hash(input&.to_date)
          end
      end

      def valid?
        @error_message = validate
        error_message.blank?
      end

      def value_as_date
        @value_as_date ||= begin
          year, month, day = date_as_hash.values_at(1, 2, 3).map(&:to_i)
          Time.zone.local(year, month, day).to_date
        end
      end

    private

      def normalize_date_hash(input_hash)
        raw_hash = input_hash.respond_to?(:to_unsafe_h) ? input_hash.to_unsafe_h : input_hash.to_h

        key_names_as_strings = raw_hash.keys.map(&:to_s)
        expected_date_keys   = %w[day month year]

        if (expected_date_keys - key_names_as_strings).empty?
          normalized_hash = raw_hash.transform_keys(&:to_s)
          { 1 => normalized_hash["year"], 2 => normalized_hash["month"], 3 => normalized_hash["day"] }
        else
          raw_hash.transform_keys do |key|
            key.to_s.match?(/\A\d+\z/) ? key.to_i : key
          end
        end
      end

      def convert_to_hash(date)
        return unless date

        { 3 => date.day, 2 => date.month, 1 => date.year }
      end

      def date_missing? = date_as_hash.nil?

      def invalid_date?
        return true if date_as_hash[1].to_i.zero?

        value_as_date
        false
      rescue ArgumentError
        true
      end

      def validate
        return self.class::DATE_MISSING_MESSAGE if date_missing?
        return self.class::INVALID_FORMAT_MESSAGE if invalid_date?

        extra_validation_error_message if respond_to?(:extra_validation_error_message, true)
      end
    end
  end
end
