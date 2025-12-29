class SpecObjectFormatter
  attr_reader :formatted_object, :fake_schools

  def initialize(object, indent = 0)
    @fake_schools = []
    @fake_delivery_partner = []

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
        "#{padding}  #{k}: #{spec_format(anonymise(k, v), indent + 2)}"
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

  FakeSchool = Struct.new(:urn, :name, :original_urn, :original_name, keyword_init: true) do
    def to_h
      { urn:, name: }
    end
  end

  FakeDeliveryPartner = Struct.new(:id, :name, :original_id, :original_name, keyword_init: true) do
    def to_h
      { id:, name: }
    end
  end

  def anonymise(key, value)
    case key
    when :trn then "1111111"
    when :full_name then "A Teacher"
    when :preferred_identity_email then "a.teacher@example.com"
    when :school
      fake_school(**value)
    else
      value
    end
  end

  def fake_school(urn:, name:)
    school = if (matching_school = fake_schools.find { |fs| fs.original_urn == urn.to_s })
               matching_school
             else
               num = fake_schools.count.next

               FakeSchool.new(
                 original_urn: urn.to_s,
                 urn: (100_000 + num).to_s,
                 original_name: name,
                 name: "School #{num}"
               ).tap do |new_fake_school|
                 @fake_schools << new_fake_school
               end
             end

    school.to_h
  end

  def fake_delivery_partner(id:, name:)
    delivery_partner = if (matching_delivery_partner = fake_delivery_partner.find { |fdp| fdp.original_id == id.id })
                         matching_delivery_partner
                       else
                         num = fake_Delivery_partners.count.next

                         FakeDeliveryPartner.new(
                           original_id: id.to_s,
                           id: (100_000 + num).to_s,
                           original_name: name,
                           name: "School #{num}"
                         ).tap do |new_fake_delivery_partner|
                           @fake_Delivery_partners << new_fake_delivery_partner
                         end
                       end

    delivery_partner.to_h
  end
end
