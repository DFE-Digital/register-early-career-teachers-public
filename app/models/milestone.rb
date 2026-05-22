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

  validates :schedule_id, presence: { message: "Choose a schedule" }

  # TODO: Add milestone start date validations (sensible values within the contract period)
  validates :start_date,
            presence: { message: "Enter a start date" }

  # TODO: Add "if start_date.present?" to milestone validation
  validates :milestone_date,
            comparison: { greater_than: :start_date, message: "Milestone date must be after the start date" },
            allow_nil: true

  validates :declaration_type,
            uniqueness: {
              message: "Can be used once per schedule",
              scope: :schedule_id
            }

  scope :in_declaration_order, -> { order(declaration_type: "asc") }
end
