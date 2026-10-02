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
  validates :output_fee_percentage,
            presence: { message: "Output fee percentage is required" },
            numericality: {
              in: 0..100,
              allow_nil: true,
              message: "Output fee percentage must be between 0 and 100"
            }
  validates :service_fee_proportion,
            presence: { message: "Service fee proportion is required" },
            if: -> { output_fee_proportion.present? }

  validate :sum_of_proportions_equals_one,
           if: -> { output_fee_proportion? && service_fee_proportion? }

  validate :band_belongs_to_contracts_framework_agreement

  delegate :capacity, :min_declarations, :max_declarations, :letter, to: :band

  def output_fee_percentage
    (output_fee_proportion * 100).to_i if output_fee_proportion
  end

  def output_fee_percentage=(val)
    self.output_fee_proportion = val.present? ? val.to_d / 100 : nil
    self.service_fee_proportion = output_fee_proportion.present? ? 1 - output_fee_proportion : nil
  end

  def service_fee_percentage
    (service_fee_proportion * 100).to_i if service_fee_proportion
  end

private

  def band_belongs_to_contracts_framework_agreement
    return unless band && banded_fee_structure&.contract
    return if band.framework_agreement == banded_fee_structure.contract.framework_agreement

    errors.add(:band, "must belong to the contract's lead provider framework agreement")
  end

  def sum_of_proportions_equals_one
    errors.add(:base, "Sum of proportions must equal 1") unless
      (output_fee_proportion + service_fee_proportion).to_d == 1.0.to_d
  end
end
