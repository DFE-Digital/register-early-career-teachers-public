module Schools
  module RegisterECTWizard
    class StartDateStep < Step
      attr_accessor :start_date

      validates :start_date, ect_start_date: true

      def self.permitted_params
        %i[start_date]
      end

      def persist
        ect.update!(start_date: start_date_formatted)
      end

      def next_step
        :working_pattern
      end

      def previous_step
        :email_address
      end

      def start_date_formatted
        Schools::Validation::ECTStartDate.new(ect_start_date_as_hash: start_date).formatted_start_date
      end

      def start_date=(value)
        if value.is_a?(String)
          # Convert string to hash
          @start_date = string_to_date_hash(value)
        elsif value.is_a?(Hash)
          # Assign directly if it's a hash
          @start_date = value
        else
          raise ArgumentError, "Invalid date format. Must be a String or Hash."
        end
      end

      def string_to_date_hash(date_string)
        # Parse the string to extract the month and year
        date = Date.parse("1 #{date_string}")

        # Return the hash in the desired format
        { 3 => 1, 2 => date.month, 1 => date.year }
      end

    end
  end
end
