class Contract::FeeStructure::FlatRate < ApplicationRecord
  self.table_name = :contract_fee_structure_flat_rates

  validates :recruitment_target,
            presence: { message: "Recruitment target is required" },
            numericality: { greater_than: 0, message: "Value must be greater than 0" }
  validates :fee_per_declaration,
            presence: { message: "Fee per declaration is required" },
            numericality: { greater_than: 0, message: "Amount must be greater than 0" }
end
