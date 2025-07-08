module Events
  class TransitionDescription
    def self.for(...) = new(...).describe

    def initialize(attribute_name, from:, to:)
      @attribute_name = attribute_name
      @from = from
      @to = to
    end

    def describe
      case
      when @from.blank? && @to.blank?
        "#{@attribute_name.humanize} is not set"
      when @from.blank?
        "#{@attribute_name.humanize} set to #{format(@to)}"
      when @to.blank?
        "#{@attribute_name.humanize} #{format(@from)} removed"
      when @from == @to
        "#{@attribute_name.humanize} #{format(@from)} unchanged"
      else
        "#{@attribute_name.humanize} changed from #{format(@from)} to #{format(@to)}"
      end
    end

  private

    def format(value)
      formatted_value = case value
                        when Date
                          value.to_formatted_s(:govuk_short)
                        else
                          value
                        end

      %('#{formatted_value}')
    end
  end
end
