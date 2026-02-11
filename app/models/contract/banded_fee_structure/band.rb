class Contract::BandedFeeStructure::Band < ApplicationRecord
  self.table_name = "contract_banded_fee_structure_bands"

  belongs_to :banded_fee_structure,
             class_name: "Contract::BandedFeeStructure"

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
  validate :declaration_boundaries_sequential_without_gaps,
           if: -> { min_declarations? && max_declarations? }

private

  def sum_of_ratios_equals_one
    errors.add(:base, "Sum of ratios must equal 1") unless
      (output_fee_ratio + service_fee_ratio).to_d == 1.0.to_d
  end

  def declaration_boundaries_sequential_without_gaps
    return unless banded_fee_structure

    ordered_bands = banded_fee_structure.bands.sort_by(&:min_declarations)
    previous_band_max_declarations = if ordered_bands.empty?
                                       0
                                     else
                                       ordered_bands.last.max_declarations
                                     end

    errors.add(:base, "Declaration boundaries must be sequential without gaps") unless
      min_declarations == previous_band_max_declarations + 1
  end
end
