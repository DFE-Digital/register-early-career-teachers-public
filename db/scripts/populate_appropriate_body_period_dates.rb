# RIAB remodelling to AppropriateBodyPeriod adoption of Interval concern
#
# started_on and finished_on dates bound induction periods owned by the Appropriate Body.
# There are four flavours of AB and only two are currently active, Teaching School Hubs and National Bodies.
# This script sets logical values for all ABP records based on type and the organisation's operating window.
#
require "csv"

class PopulateAppropriateBodyPeriodDates
  BODY_TYPE_DATES = {
    "local_authority" => {
      started_on: LocalAuthority::APPROPRIATE_BODY[:introduced_on],
      finished_on: LocalAuthority::APPROPRIATE_BODY[:retired_on]
    },
    "teaching_school_hub" => {
      started_on: TeachingSchoolHub::APPROPRIATE_BODY[:introduced_on],
      finished_on: nil
    }
  }.freeze

  NATIONAL_BODY_DATES = {
    NationalBody::ISTIP => { started_on: Date.new(2011, 8, 31), finished_on: nil },
    NationalBody::ESP => { started_on: Date.new(2024, 4, 1), finished_on: nil },
    NationalBody::NTA => { started_on: Date.new(2013, 8, 31), finished_on: Date.new(2024, 9, 1) }
  }.freeze

  REPORT_HEADERS = %w[
    id
    name
    body_type
    provisioning_school_urn
    started_on
    finished_on
  ].freeze

  def call
    ActiveRecord::Base.transaction do
      AppropriateBodyPeriod.find_each { |appropriate_body_period| update(appropriate_body_period) }
    end

    report
  end

private

  # @return [Pathname]
  def output_path
    Rails.root.join("tmp/appropriate_body_period_dates.csv")
  end

  # @param appropriate_body_period [AppropriateBodyPeriod]
  # @return [Boolean, nil]
  def update(appropriate_body_period)
    return if appropriate_body_period.started_on.present?

    dates = dates_for(appropriate_body_period)
    # If a linked Teaching School's dates conflict we likely have the wrong school or GIAS data.
    return if dates[:finished_on] && dates[:finished_on] < dates[:started_on]

    appropriate_body_period.update!(dates)
  end

  # @param appropriate_body_period [AppropriateBodyPeriod]
  # @return [Hash{Symbol => Date}]
  def dates_for(appropriate_body_period)
    return NATIONAL_BODY_DATES.fetch(appropriate_body_period.name) if appropriate_body_period.national?
    return teaching_school_dates(appropriate_body_period) if appropriate_body_period.teaching_school?

    BODY_TYPE_DATES.fetch(appropriate_body_period.body_type)
  end

  # A school cannot act as an appropriate body before it opened, opening date is the earliest start date.
  # A school that closed stopped operating as an appropriate body, closing date is the latest end date.
  # Actual AB operating dates may differ but these should be logical hard limits.
  #
  # @param appropriate_body_period [AppropriateBodyPeriod]
  # @return [Hash{Symbol => Date}]
  def teaching_school_dates(appropriate_body_period)
    school = appropriate_body_period.provisioning_school

    {
      started_on: [school&.opened_on, School::APPROPRIATE_BODY[:introduced_on]].compact.max,
      finished_on: [school&.closed_on, School::APPROPRIATE_BODY[:retired_on]].compact.min
    }
  end

  def report
    CSV.open(output_path, "w") do |csv|
      csv << REPORT_HEADERS

      AppropriateBodyPeriod.find_each do |appropriate_body_period|
        csv << [
          appropriate_body_period.id,
          appropriate_body_period.name,
          appropriate_body_period.body_type,
          appropriate_body_period.provisioning_school&.urn,
          appropriate_body_period.started_on,
          appropriate_body_period.finished_on
        ]
      end
    end
  end
end
