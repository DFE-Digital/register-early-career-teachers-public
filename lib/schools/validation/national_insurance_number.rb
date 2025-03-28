module Schools
  module Validation
    class NationalInsuranceNumber
      REGEXP = /\A(?!BG)(?!GB)(?!NK)(?!KN)(?!TN)(?!NT)(?!ZZ)[A-Z&&[^DFIQUV]][A-Z&&[^DFIOQUV]][0-9]{6}[A-D]\z/

      attr_reader :nino, :formatted_nino, :error

      def initialize(nino)
        @nino = nino
        @formatted_nino, @error = parse_nino
      end

      def valid?
        error.nil?
      end

    private

      def parse_nino
        parsed = nino.to_s.upcase.gsub(/\s*/, "")
        return [nil, "Enter a National Insurance Number"] if parsed.blank?
        return [nil, "Enter a National Insurance Number in the correct format"] unless REGEXP.match?(parsed)

        [parsed, nil]
      end
    end
  end
end
