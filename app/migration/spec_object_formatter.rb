class SpecObjectFormatter
  attr_reader :formatted_object

  def initialize(object, indent = 0)
    @formatted_object = spec_format(object, indent)
  end

private

  def spec_format(object, indent)
    padding = " " * indent

    case object
    when Date
      "Date.new(#{object.year}, #{object.month}, #{object.day})"
    when Time
      "Time.zone.local(#{object.year}, #{object.month}, #{object.day}, #{object.hour}, #{object.min}, #{object.sec})"
    when Hash
      return "{}" if object.empty?

      pairs = object.map do |k, v|
        # FIXME: add safety measure here to prevent real TRNs/URNs/names leaking
        "#{padding}  #{k}: #{spec_format(v, indent + 2)}"
      end

      "{\n#{pairs.join(",\n")}\n#{padding}}"
    when Array
      return "[]" if object.empty?

      items = object.map { |v| "#{padding}  #{spec_format(v, indent + 2)}" }

      "[\n#{items.join(",\n")}\n#{padding}]"
    else
      object.inspect
    end
  end
end
