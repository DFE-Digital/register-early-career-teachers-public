class Contract::BandedFeeStructure < ApplicationRecord
  self.table_name = "contract_banded_fee_structures"

  # Associations
  has_many :bands,
           -> { order(min_declarations: :asc) },
           class_name: "Contract::BandedFeeStructure::Band",
           inverse_of: :banded_fee_structure,
           dependent: :destroy
  has_many :contracts, foreign_key: "contract_banded_fee_structure_id", inverse_of: :contract_banded_fee_structure

  # Validations
  validates :recruitment_target,
            presence: { message: "Recruitment target is required" },
            numericality: {
              greater_than_or_equal_to: 0,
              only_integer: true,
              message: "Recruitment target must be a number greater than zero"
            }
  validates :uplift_fee_per_declaration,
            presence: { message: "Uplift fee per declaration is required" },
            numericality: {
              greater_than_or_equal_to: 0,
              message: "Uplift fee per declaration must be greater than or equal to zero"
            }
  validates :monthly_service_fee,
            presence: { message: "Monthly service fee is required" },
            numericality: {
              greater_than_or_equal_to: 0,
              message: "Monthly service fee must be greater than or equal to zero"
            }
  validates :setup_fee,
            presence: { message: "Setup fee is required" },
            numericality: {
              greater_than_or_equal_to: 0,
              message: "Setup fee must be greater than or equal to zero"
            }
end
