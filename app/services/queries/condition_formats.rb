module Queries
  module ConditionFormats
    def extract_conditions(list, allowlist: nil, uuids: false, integers: false)
      conditions = case list
                   when String
                     list.split(",")
                   when Array
                     list.compact
                   else
                     list
                   end

      conditions.select! { |uuid| uuid_valid?(uuid) } if uuids
      conditions.select! { |value| integer_valid?(value) } if integers

      return conditions if allowlist.blank?

      case conditions
      when Array
        conditions.intersection(allowlist)
      else
        conditions.in?(allowlist) ? conditions : nil
      end
    end

  private

    def uuid_valid?(uuid)
      uuid =~ /\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/
    end

    def integer_valid?(value)
      value.to_s.match?(/\A\d+\z/)
    end
  end
end
