class UnclaimedIndexComponent < ApplicationComponent
  renders_one :detailed_review_section, -> {
    UnclaimedIndex::DetailedReviewSectionComponent.new(appropriate_body:)
  }

  attr_reader :appropriate_body

  def initialize(appropriate_body:)
    @appropriate_body = appropriate_body
  end

  class << self
    def period
      (june_or_after? ? [this_year, next_year] : [last_year, this_year]).join "/"
    end

  private

    def june_or_after?
      Time.current.month > 5
    end

    def this_year
      Time.current.year
    end

    def last_year
      Time.current.prev_year.year
    end

    def next_year
      Time.current.next_year.year
    end
  end

private

  def before_render
    with_detailed_review_section
  end
end
