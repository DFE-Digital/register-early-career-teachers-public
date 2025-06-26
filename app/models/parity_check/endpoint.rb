module ParityCheck
  class Endpoint < ApplicationRecord
    self.table_name = "parity_check_endpoints"

    has_many :requests

    validates :path, presence: true
    validates :method, presence: true, inclusion: { in: %i[get post put] }
    validate :options_is_a_hash
    validate :path_does_not_contain_query_params

    def method
      super&.to_sym
    end

    def options=(value)
      super(value || {})
    end

    def options
      value = super
      value.deep_symbolize_keys if value.respond_to?(:deep_symbolize_keys)
    end

    def group_name
      match = path.match(%r{/api/v\d+/(?<group>[^/?]+)})
      match ? match[:group]&.to_sym : :miscellaneous
    end

    def description
      pagination_note = options[:paginate] ? " (all pages)" : ""
      query_string = options[:query].present? ? "?#{CGI.unescape(options[:query].to_query)}" : ""
      "#{method.to_s.upcase} #{path}#{query_string}#{pagination_note}"
    end

  private

    def options_is_a_hash
      errors.add(:options, "Options must be a hash") unless options.is_a?(Hash)
    end

    def path_does_not_contain_query_params
      return unless path&.include?("?")

      errors.add(:path, "Path should not contain query parameters; use options[:query] instead.")
    end
  end
end
