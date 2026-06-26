class Contract::BandedFeeStructure < ApplicationRecord
  self.table_name = "contract_banded_fee_structures"

  # Associations
  belongs_to :contract

  has_many :band_terms,
           -> { left_joins(:band).order("active_lead_provider_bands.allocation_order ASC, contract_banded_fee_structure_band_terms.min_declarations ASC") },
           class_name: "Contract::BandedFeeStructure::BandTerm",
           inverse_of: :banded_fee_structure,
           dependent: :destroy

  accepts_nested_attributes_for :bands

  # Validations
  validates :contract_id, uniqueness: { message: "Contract with the same banded fee structure already exist" }

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
            numericality: {
              greater_than_or_equal_to: 0,
              message: "Monthly service fee must be greater than or equal to zero",
              allow_nil: true
            }
  validates :setup_fee,
            presence: { message: "Setup fee is required" },
            numericality: {
              greater_than_or_equal_to: 0,
              message: "Setup fee must be greater than or equal to zero"
            }
end
