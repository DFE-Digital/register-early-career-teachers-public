module Schools
  module Validation
    class CorrectedName
      attr_reader :formatted_name, :error

      def initialize(name)
        @name = name
        @formatted_name, @error = parse_name
      end

      def valid?
        error.nil?
      end

    private

      attr_reader :name

      def parse_name
        parsed_name = name.strip.presence
        return [nil, "Enter the full, correct name"] unless parsed_name
        return [nil, "Corrected name must be 70 characters or less"] if parsed_name.size > 70

        [parsed_name, nil]
      end
    end
  end
end
