module CommonInductionPeriodValidation
  extend ActiveSupport::Concern

  included do
    validates :appropriate_body_id,
              presence: { message: "Select an appropriate body" }

    validate :started_on_from_september_2021_onwards, if: -> { started_on.present? }

    validate :started_on_not_in_future, if: -> { started_on.present? }
    validate :finished_on_not_in_future, if: -> { finished_on.present? }
  end

  def started_on_from_september_2021_onwards
    return if started_on >= Date.new(2021, 9, 1)

    errors.add(:started_on, "Enter a start date after 1 September 2021")
  end

  def started_on_not_in_future
    return if started_on <= Date.current

    errors.add(:started_on, "Start date cannot be in the future")
  end

  def finished_on_not_in_future
    return if finished_on <= Date.current

    errors.add(:finished_on, "End date cannot be in the future")
  end
end
