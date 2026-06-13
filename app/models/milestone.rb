class Milestone < ApplicationRecord
  enum :declaration_type,
       %w[
         started
         retained-1
         retained-2
         retained-3
         retained-4
         completed
         extended-1
         extended-2
         extended-3
       ].index_by(&:itself),
       validate: { message: "Choose a valid declaration type" }

  belongs_to :schedule

  # Validations
  validates :schedule_id, presence: { message: "Choose a schedule" }
  validates :start_date, presence: { message: "Enter a start date" }

  validates :milestone_date,
            comparison: {
              greater_than: :start_date,
              message: "Milestone date must be after the start date"
            },
            if: -> { start_date.present? },
            allow_nil: true

  validates :declaration_type,
            uniqueness: {
              message: "Can be used once per schedule",
              scope: :schedule_id
            }
  validate :start_date_within_contract_period,
           if: -> { start_date.present? }

  scope :in_declaration_order, -> { order(declaration_type: "asc") }

private

  # Contract periods start on 1st June
  def start_date_within_contract_period
    return unless schedule&.contract_period

    contract_start = schedule.contract_period.started_on

    return if start_date >= contract_start

    errors.add(:start_date, "The start date must be on or after the contract start date (#{contract_start.to_fs(:govuk)})")
  end
end
