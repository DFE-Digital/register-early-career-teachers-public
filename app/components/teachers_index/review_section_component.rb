module TeachersIndex
  class ReviewSectionComponent < ApplicationComponent
    include Rails.application.routes.url_helpers

    def initialize(appropriate_body_period:)
      @appropriate_body = appropriate_body_period
    end

    def render?
      Rails.application.config.enable_appropriate_body_records_to_review
    end

  private

    attr_reader :appropriate_body

    def number_of_ect_records_to_review
      appropriate_body.unclaimed_ect_at_school_periods.count
    end
  end
end
