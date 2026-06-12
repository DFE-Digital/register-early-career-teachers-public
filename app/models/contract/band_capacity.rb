class Contract::BandCapacity < ApplicationRecord
  self.table_name = "contract_band_capacities"

  # Associations
  belongs_to :active_lead_provider

  has_many :contract_banded_fee_structure_bands,
           class_name: "Contract::BandedFeeStructure::Band",
           inverse_of: :contract_band_capacity

  # Validations
  validates :min_declarations,
            presence: { message: "Min declarations is required" },
            numericality: {
              greater_than: 0,
              only_integer: true,
              message: "Min declarations must be a number greater than zero"
            }
  validates :max_declarations,
            presence: { message: "Max declarations is required" },
            numericality: {
              greater_than: :min_declarations,
              only_integer: true,
              message: "Max declarations must be a number greater than min declarations"
            }
end
