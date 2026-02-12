module ParityCheck
  class Response < ApplicationRecord
    self.table_name = "parity_check_responses"

    belongs_to :request

    delegate :run, to: :request

    before_validation :clear_bodies, if: :bodies_matching?
    before_validation :calculate_match_rate

    validates :request, presence: true
    validates :ecf_status_code, inclusion: { in: 100..599 }
    validates :rect_status_code, inclusion: { in: 100..599 }
    validates :ecf_time_ms, numericality: { greater_than: 0 }
    validates :rect_time_ms, numericality: { greater_than: 0 }
    validates :page, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true, uniqueness: { scope: :request_id }

    scope :status_codes_matching, -> { where("ecf_status_code = rect_status_code") }
    scope :status_codes_different, -> { where("ecf_status_code != rect_status_code") }
    scope :bodies_different, -> { where("ecf_body != rect_body") }
    scope :bodies_matching, -> { where(ecf_body: nil, rect_body: nil) } # We nil matching response bodies.
    scope :matching, -> { status_codes_matching.bodies_matching }
    scope :different, -> { status_codes_different.or(bodies_different) }
    scope :ordered_by_page, -> { order(:page) }

    def rect_performance_gain_ratio
      return unless ecf_time_ms && rect_time_ms

      ratio = ecf_time_ms.to_f / rect_time_ms

      (ratio < 1 ? -(1 / ratio) : ratio).round(1)
    end

    def matching?
      !different?
    end

    def different?
      [ecf_status_code, ecf_body] != [rect_status_code, rect_body]
    end

    def description
      if page
        "Response for page #{page}"
      else
        "Response"
      end
    end

    def bodies_matching?
      ecf_body == rect_body
    end

    def bodies_different?
      !bodies_matching?
    end

    def body_ids_matching?
      ecf_body_ids == rect_body_ids
    end

    def body_ids_different?
      !body_ids_matching?
    end

    def body_diff
      @body_diff ||= Diffy::Diff.new(ecf_body, rect_body, context: 3)
    end

    def ecf_body_hash
      @ecf_body_hash ||= parse_json_body(ecf_body)
    end

    def rect_body_hash
      @rect_body_hash ||= parse_json_body(rect_body)
    end

    def ecf_body=(value)
      super(format_body(value))
    end

    def rect_body=(value)
      super(format_body(value))
    end

    def ecf_body_ids
      return [] unless ecf_body_hash

      Array.wrap(ecf_body_hash[:data]).map { it[:id] }.sort
    end

    def rect_body_ids
      return [] unless rect_body_hash

      Array.wrap(rect_body_hash[:data]).map { it[:id] }.sort
    end

    def ecf_only_body_ids
      ecf_body_ids - rect_body_ids
    end

    def rect_only_body_ids
      rect_body_ids - ecf_body_ids
    end

  private

    def calculate_match_rate
      Rails.cache.fetch(["response", id, created_at, "match_rate"]) do
        return self.match_rate = 0 if ecf_status_code != rect_status_code
        return self.match_rate = 100 if matching?

        ecf_lines  = ecf_body.to_s.lines.to_set
        rect_lines = rect_body.to_s.lines.to_set

        diff_lines = (ecf_lines ^ rect_lines).size
        total_lines = ecf_lines.size + rect_lines.size

        self.match_rate =
          (100 * (1 - diff_lines.to_f / total_lines)).floor
      end
    end

    def format_body(body)
      parsed_json = parse_json_body(body)

      return body unless parsed_json

      pretty_json(parsed_json)
    end

    def pretty_json(ugly_json)
      JSON.pretty_generate(ugly_json)
    end

    def parse_json_body(body)
      return nil unless body

      parsed_body = JSON.parse(body)

      deep_remove_keys(parsed_body&.deep_symbolize_keys, keys_to_exclude) if parsed_body.is_a?(Hash)
    rescue JSON::ParserError
      nil
    end

    def clear_bodies
      self.ecf_body = self.rect_body = nil
    end

    def keys_to_exclude
      (request.endpoint.options[:exclude] || []).map(&:to_sym)
    end

    def deep_remove_keys(hash, keys_to_remove)
      return hash if keys_to_remove.blank?

      case hash
      when Hash
        hash.each_with_object({}) do |(key, value), result|
          next if key.in?(keys_to_remove)

          result[key] = deep_remove_keys(value, keys_to_remove)
        end
      when Array
        hash.map { |item| deep_remove_keys(item, keys_to_remove) }
      else
        hash
      end
    end
  end
end
