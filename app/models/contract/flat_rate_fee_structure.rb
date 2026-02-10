class Contract::FlatRateFeeStructure < ApplicationRecord
  self.table_name = :contract_flat_rate_fee_structures

  # Associations
  has_many :contracts, inverse_of: :flat_rate_fee_structure

  # Validations
  validates :recruitment_target,
            presence: { message: "Recruitment target is required" },
            numericality: { greater_than: 0, only_integer: true, message: "Value must be greater than 0" }
  validates :fee_per_declaration,
            presence: { message: "Fee per declaration is required" },
            numericality: { greater_than: 0, message: "Amount must be greater than 0" }
end
