class Milestone < ApplicationRecord
  enum :declaration_type,
    {
      "started" => "started",
      "retained-1" => "retained-1",
      "retained-2" => "retained-2",
      "retained-3" => "retained-3",
      "retained-4" => "retained-4",
      "completed" => "completed",
      "extended-1" => "extended-1",
      "extended-2" => "extended-2",
      "extended-3" => "extended-3"
    },
    validate: {message: "Choose a valid declaration type"}

  belongs_to :schedule

  validates :schedule_id, presence: {message: "Choose a schedule"}
  validates :start_date, presence: {message: "Enter a start date"}

  validates :declaration_type,
    uniqueness: {
      message: "Can be used once per schedule",
      scope: :schedule_id
    }

  scope :in_declaration_order, -> { order(declaration_type: "asc") }
end
