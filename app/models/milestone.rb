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

  validates :start_date,
            presence: { message: "Enter a start date" }

  validates :milestone_date,
            comparison: { greater_than: :start_date, message: "Milestone date must be after the start date" },
            if: -> { start_date.present? },
            allow_nil: true

  validates :declaration_type,
            uniqueness: {
              message: "Can be used once per schedule",
              scope: :schedule_id
            }

  scope :in_declaration_order, -> { order(declaration_type: "asc") }
end
