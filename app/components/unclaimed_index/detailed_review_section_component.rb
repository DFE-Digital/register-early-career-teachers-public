module UnclaimedIndex
  class DetailedReviewSectionComponent < ApplicationComponent
    def initialize(appropriate_body:)
      @appropriate_body = appropriate_body
    end

  private

    attr_reader :appropriate_body

    def number_of_claimable_ect_records
      36
    end

    def number_of_missing_qts_records
      7
    end

    def number_of_records_claimed_by_another_appropriate_body
      8
    end
  end
end
