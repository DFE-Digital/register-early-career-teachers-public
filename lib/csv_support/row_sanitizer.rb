module CSVSupport
  class RowSanitizer
    # Spreadsheet apps can treat cells starting with these characters
    # as formulas, which can lead to CSV formula injection.
    FORMULA_PREFIX_PATTERN = /\A[[:space:]]*[=\-+@]/

    def self.sanitize(row)
      row.map { |value| sanitize_cell(value) }
    end

    def self.sanitize_cell(value)
      return value unless value.is_a?(String)
      return value unless value.match?(FORMULA_PREFIX_PATTERN)

      "'#{value}"
    end

    private_class_method :sanitize_cell
  end
end
