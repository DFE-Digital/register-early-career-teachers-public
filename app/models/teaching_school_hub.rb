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

  has_many :appropriate_body_periods
  has_many :lead_schools, through: :appropriate_body_periods, source: :lead_schools

  validates :name, presence: true, uniqueness: true
  validate :name_is_not_an_ongoing_appropriate_body_period_name,
           if: -> { Rails.application.config.nullable_appropriate_body_period_names }

  normalizes :name, with: -> { it.squish }

  def name_is_not_an_ongoing_appropriate_body_period_name
    return if name.blank?
    return unless AppropriateBodyPeriod.where(name:).contains_date(Date.current).exists?

    errors.add(:name, "is already used by an ongoing appropriate body.")
  end

  # @return [Array<String>]
  def region_codes
    appropriate_body_periods.flat_map do |period|
      period.region_awards.select(&:active?).map { |award| award.region.code }
    end
  end

  def has_multiple_active_appropriate_body_periods? = appropriate_body_periods.count(&:active?) > 1
end
