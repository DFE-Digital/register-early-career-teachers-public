module ParityCheck
  class Response < ApplicationRecord
    self.table_name = "parity_check_responses"

    belongs_to :request

    before_validation :clear_bodies, unless: :different?

    validates :request, presence: true
    validates :ecf_status_code, inclusion: { in: 100..599 }
    validates :rect_status_code, inclusion: { in: 100..599 }
    validates :ecf_time_ms, numericality: { greater_than: 0 }
    validates :rect_time_ms, numericality: { greater_than: 0 }
    validates :page, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true, uniqueness: { scope: :request_id }

    scope :different, -> { where("ecf_status_code != rect_status_code OR ecf_body != rect_body") }
    scope :matching, -> { where("ecf_status_code = rect_status_code AND ecf_body IS NULL and rect_body IS NULL") }

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

  private

    def different?
      [ecf_status_code, ecf_body] != [rect_status_code, rect_body]
    end

    def clear_bodies
      self.ecf_body = self.rect_body = nil
    end
  end
end
