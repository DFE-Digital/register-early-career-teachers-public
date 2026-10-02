module API
  class DateTimeFormatCheck
    RFC3339_DATE_REGEX = /\A\d{4}-\d{2}-\d{2}T(\d{2}):(\d{2}):(\d{2})([.,]\d+)?(Z|[+-](\d{2})(:?\d{2})?)?\z/i

    attr_reader :value

    def initialize(value)
      @value = value
    end

    def valid?
      return false if value.blank?

      begin
        return true if value.to_s.match?(RFC3339_DATE_REGEX) && Time.zone.parse(value.to_s)
      rescue ArgumentError
        false
      end

      false
    end
    
    def invalid?
      !valid?
    end
  end
end
