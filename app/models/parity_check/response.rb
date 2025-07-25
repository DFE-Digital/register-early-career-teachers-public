module ParityCheck
  class Response < ApplicationRecord
    self.table_name = "parity_check_responses"

    belongs_to :request

    delegate :run, to: :request

    before_validation :clear_bodies, if: :bodies_matching?

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

    def match_rate
      matching? ? 100 : 0
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
      super(pretty_json(value))
    end

    def rect_body=(value)
      super(pretty_json(value))
    end

  private

    def pretty_json(value)
      parsed_json = parse_json_body(value)
      parsed_json ? JSON.pretty_generate(parsed_json) : value
    end

    def parse_json_body(body)
      JSON.parse(body)&.deep_symbolize_keys if body
    rescue JSON::ParserError
      nil
    end

    def clear_bodies
      self.ecf_body = self.rect_body = nil
    end
  end
end
