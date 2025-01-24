module CommonInductionPeriodValidation
  extend ActiveSupport::Concern

  included do
    validate :started_on_from_september_2021_onwards, if: -> { started_on.present? }
  end

  def started_on_from_september_2021_onwards
    return if started_on >= Date.new(2021, 9, 1)

    errors.add(:started_on, "Enter a start date after 1 September 2021")
  end
end
