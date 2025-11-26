class Declaration < ApplicationRecord
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
       validate: { message: "Choose a valid declaration type" }

  belongs_to :training_period
  has_many :statement_line_items, class_name: "Statement::LineItem"

  validates :training_period, presence: { message: "Choose a training period" }
end
