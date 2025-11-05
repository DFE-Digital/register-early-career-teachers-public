module UnclaimedIndex
  class DetailedReviewSectionComponent < ApplicationComponent
    attr_reader :appropriate_body_period

    delegate :unclaimed_ect_at_school_periods, to: :appropriate_body_period, allow_nil: true
    delegate :claimable, :without_qts_award, :claimed_by_different_appropriate_body, to: :unclaimed_ect_at_school_periods, allow_nil: true
    delegate :count, to: :claimable, prefix: true
    delegate :count, to: :without_qts_award, prefix: true
    delegate :count, to: :claimed_by_different_appropriate_body, prefix: true

    alias_method :number_of_claimable_ect_records, :claimable_count
    alias_method :number_of_missing_qts_records, :without_qts_award_count
    alias_method :number_of_records_claimed_by_another_appropriate_body, :claimed_by_different_appropriate_body_count

    def initialize(appropriate_body_period:)
      @appropriate_body_period = appropriate_body_period
    end
  end
end
