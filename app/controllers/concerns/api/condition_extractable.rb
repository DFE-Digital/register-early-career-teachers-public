module API
  module ConditionExtractable
    extend ActiveSupport::Concern

    protected

    def extract_conditions(list, uuids: false, integers: false)
      return if list.blank?

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

      conditions
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
