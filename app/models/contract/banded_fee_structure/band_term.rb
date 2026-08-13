class Contract::BandedFeeStructure::BandTerm < ApplicationRecord
  self.table_name = "contract_banded_fee_structure_band_terms"

  # Associations
  belongs_to :banded_fee_structure,
             class_name: "Contract::BandedFeeStructure"

  belongs_to :band,
             class_name: "FrameworkAgreement::Band"

  # Validations
  validates :fee_per_declaration,
            presence: { message: "Fee per declaration is required" },
            numericality: {
              greater_than: 0,
              message: "Fee per declaration must be a number greater than zero"
            }
  validates :output_fee_ratio,
            presence: { message: "Output fee ratio is required" },
            numericality: {
              in: 0..1,
              message: "Output fee ratio must be between 0 and 1"
            }
  validates :service_fee_ratio,
            presence: { message: "Service fee ratio is required" },
            numericality: {
              in: 0..1,
              message: "Service fee ratio must be between 0 and 1"
            }

  validate :sum_of_ratios_equals_one,
           if: -> { output_fee_ratio? && service_fee_ratio? }

  validate :band_belongs_to_contracts_framework_agreement

  delegate :capacity, :min_declarations, :max_declarations, :letter, to: :band

  def output_fee_percentage
    (output_fee_ratio * 100).to_i if output_fee_ratio
  end

  def output_fee_percentage=(val)
    self.output_fee_ratio = val.present? ? val.to_d / 100 : nil
  end

  def service_fee_percentage
    (service_fee_ratio * 100).to_i if service_fee_ratio
  end

  def service_fee_percentage=(val)
    self.service_fee_ratio = val.present? ? val.to_d / 100 : nil
  end

private

  def band_belongs_to_contracts_framework_agreement
    return unless band && banded_fee_structure&.contract
    return if band.framework_agreement == banded_fee_structure.contract.framework_agreement

    errors.add(:band, "must belong to the contract's active lead provider")
  end

  def sum_of_ratios_equals_one
    errors.add(:base, "Sum of ratios must equal 1") unless
      (output_fee_ratio + service_fee_ratio).to_d == 1.0.to_d
  end
end
