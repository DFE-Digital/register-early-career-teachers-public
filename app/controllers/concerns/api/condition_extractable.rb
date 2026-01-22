module API
  module ConditionExtractable
    extend ActiveSupport::Concern

  protected

    def extract_conditions(list, type: nil)
      return if list.blank?

      conditions = case list
                   when String
                     list.split(",")
                   when Array
                     list.compact
                   else
                     list
                   end

      case type
      when :uuid
        conditions.select! { |uuid| uuid_valid?(uuid) }
      when :integer
        conditions.select! { |value| integer_valid?(value) }
      end

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
