# Teaching School Hubs replaced Teaching Schools in 2021.
#
# A hub runs one period per provisioning school. Where its regions are led
# by two schools, the second may provision its own period, and the two then
# run at once. That move renames all three, because two concurrent periods
# cannot share a name.
#
# 1 hub / 1 period          1 hub / 2 periods
# ──────────────────────    ──────────────────────────────────────
# Example Hub               Example Hub Network
# └─ (unnamed period)       ├─ "Example Hub (region 1)"
#    ├ region 1  school A   │    └ region 1  school A
#    └ region 2  school B   └─ "Example Hub (region 2)"
#                                └ region 2  school B
#
# Example:
#   "Example Hub"     -> "Example Hub Network"
#   (unnamed period)  -> "Example Hub (region 1)"
#   (new period)      -> "Example Hub (region 2)"
#
class TeachingSchoolHub < ApplicationRecord
  ACTED_AS_APPROPRIATE_BODY_DATES = {
    introduced_on: Date.new(2021, 9, 1),
    retired_on: nil,
  }.freeze

  has_many :appropriate_body_periods, -> { order(finished_on: :desc) }
  has_many :lead_schools, through: :appropriate_body_periods, source: :lead_schools

  validates :name, presence: true, uniqueness: true
  validate :name_is_not_an_ongoing_appropriate_body_period_name,
           if: -> { Rails.application.config.nullable_appropriate_body_period_names }

  normalizes :name, with: -> { it.squish }

  def has_multiple_ongoing_appropriate_body_periods? = appropriate_body_periods.count { it.range.cover?(Date.current) } > 1

  # @return [Array<String>]
  def region_codes
    appropriate_body_periods.flat_map do |period|
      period.active_region_awards.map { |award| award.region.code }
    end
  end

private

  def name_is_not_an_ongoing_appropriate_body_period_name
    return if name.blank?

    ongoing_appropriate_bodies = AppropriateBodyPeriod.with_display_name(name).contains_date(Date.current)
    if persisted?
      ongoing_appropriate_bodies = ongoing_appropriate_bodies.where(
        "appropriate_body_periods.teaching_school_hub_id IS DISTINCT FROM ? OR appropriate_body_periods.name IS NOT NULL", id
      )
    end
    return unless ongoing_appropriate_bodies.exists?

    errors.add(:name, "is already used by an ongoing appropriate body.")
  end
end
