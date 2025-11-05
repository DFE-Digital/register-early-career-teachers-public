class UnclaimedIndexComponent < ApplicationComponent
  renders_one :detailed_review_section, -> {
    UnclaimedIndex::DetailedReviewSectionComponent.new(appropriate_body_period:)
  }

  attr_reader :appropriate_body_period

  def initialize(appropriate_body_period:)
    @appropriate_body_period = appropriate_body_period
  end

  def period
    (june_or_after? ? [this_year, next_year] : [last_year, this_year]).join "/"
  end

private

  def before_render
    helpers.page_data(
      title: "ECT induction records to review for #{period}",
      backlink_href: helpers.ab_teachers_path
    )

    with_detailed_review_section
  end

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
