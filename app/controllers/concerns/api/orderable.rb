module API
  module Orderable
    extend ActiveSupport::Concern

    SORT_ORDER = { "+" => "ASC", "-" => "DESC" }.freeze

  protected

    def sort_order(sort:, model:, default: {})
      return default unless sort

      sort_parts = sort.split(",")
      sort_parts
        .map { |sort_part| convert_sort_part_to_active_record_order(sort_part, model) }
        .compact
        .join(", ")
        .presence
    end

  private

    def convert_sort_part_to_active_record_order(sort_part, model)
      extracted_sort_sign = /\A[+-]/.match?(sort_part) ? sort_part.slice!(0) : "+"
      sort_order = SORT_ORDER[extracted_sort_sign]
      sort_attribute = transform_sort_attribute(sort_part)

      return unless sort_attribute.in?(model.attribute_names)

      "#{model.table_name}.#{sort_attribute} #{sort_order}"
    end

    def transform_sort_attribute(attribute)
      return attribute unless attribute == "updated_at"

      updated_at_attribute
    end

    def updated_at_attribute
      "api_updated_at"
    end
  end
end
