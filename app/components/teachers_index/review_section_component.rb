module TeachersIndex
  class ReviewSectionComponent < ApplicationComponent
    include Rails.application.routes.url_helpers

    def initialize(appropriate_body:)
      @appropriate_body = appropriate_body
    end

  private

    attr_reader :appropriate_body

    def number_of_ect_records_to_review
      appropriate_body.pending_induction_submissions.count
    end
  end
end
