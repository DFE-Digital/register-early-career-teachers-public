class Statement::Adjustment < ApplicationRecord
  belongs_to :statement

  validates :payment_type, presence: { message: "Payment type is required" }
  validates :amount, presence: { message: "Amount is required" }
  validates :amount, numericality: { other_than: 0, message: "Amount must be greater than 0" }
  # Only needed for migrating data from ECF; can be removed later.
  validates :api_id, uniqueness: { case_sensitive: false, message: "API id already exists for another statement adjustment" }
end
