class Statement::Adjustment < ApplicationRecord
  belongs_to :statement

  validates :payment_type, presence: { message: "Payment type is required" }
  validates :amount, presence: { message: "Amount is required" }
  validates :amount, numericality: { other_than: 0, message: "Amount must be greater than 0" }
  validate :amount_min_and_max_values

  # Only needed for migrating data from ECF; can be removed later.
  validates :api_id, uniqueness: { case_sensitive: false, message: "API id already exists for another statement adjustment" }

private

  def amount_min_and_max_values
    return if errors.any?

    if amount < -1_000_000.0
      errors.add(:amount, "Amount must be greater than or equal to -1,000,000")
    end

    if amount > 1_000_000.0
      errors.add(:amount, "Amount must be less than or equal to 1,000,000")
    end
  end
end
