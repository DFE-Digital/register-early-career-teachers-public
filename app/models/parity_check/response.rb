module ParityCheck
  class Response < ApplicationRecord
    self.table_name = "parity_check_responses"

    belongs_to :request

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

  private

    def bodies_matching?
      ecf_body == rect_body
    end

    def clear_bodies
      self.ecf_body = self.rect_body = nil
    end
  end
end
