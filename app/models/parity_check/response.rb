module ParityCheck
  class Response < ApplicationRecord
    self.table_name = "parity_check_responses"

    belongs_to :request

    validates :request, presence: true
    validates :ecf_status_code, inclusion: { in: 100..599 }
    validates :rect_status_code, inclusion: { in: 100..599 }
    validates :ecf_body, presence: true, if: :different?
    validates :rect_body, presence: true, if: :different?
    validates :ecf_time_ms, numericality: { greater_than: 0 }
    validates :rect_time_ms, numericality: { greater_than: 0 }

  private

    def different?
      [ecf_status_code, ecf_body] != [rect_status_code, rect_body]
    end
  end
end
