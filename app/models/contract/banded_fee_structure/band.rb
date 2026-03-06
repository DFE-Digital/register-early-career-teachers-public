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
  validate :first_band_min_declarations_is_one
  validate :band_consistency_across_active_lead_provider

  def capacity
    max_declarations - min_declarations + 1
  end

private

  def sum_of_ratios_equals_one
    errors.add(:base, "Sum of ratios must equal 1") unless
      (output_fee_ratio + service_fee_ratio).to_d == 1.0.to_d
  end

  def first_band_min_declarations_is_one
    first_band = banded_fee_structure&.bands&.first || self

    return if first_band.min_declarations == 1

    errors.add(:min_declarations, "The first band's min declarations must be 1")
  end

  def declaration_boundaries_sequential_without_gaps
    return unless banded_fee_structure

    ordered_bands = banded_fee_structure
      .bands
      .where.not(id:)
      .to_a
      .push(self)
      .sort_by(&:min_declarations)

    return if ordered_bands.each_cons(2).all? { |a, b| a.max_declarations + 1 == b.min_declarations }

    errors.add(:base, "Declaration boundaries must be sequential without gaps")
  end

  # As the banded calculations take into account previous statements for
  # the same active lead provider, we need to ensure that the bands remain
  # consistent across all contracts associated with the same active lead provider.
  def band_consistency_across_active_lead_provider
    active_lead_provider = banded_fee_structure&.contract&.active_lead_provider
    return unless active_lead_provider

    bands_for_active_lead_provider = self.class
        .joins(banded_fee_structure: { contract: :active_lead_provider })
        .where(contracts: { active_lead_provider: })
        .where.not(id:)
        .to_a
        .push(self)

    attributes_to_ignore = %w[id banded_fee_structure_id created_at updated_at].freeze
    unique_bands_by_index = bands_for_active_lead_provider
      .group_by { it.banded_fee_structure.reload.bands.index(it) || it.banded_fee_structure.bands.count }
      .transform_values { |bands| bands.map { it.attributes.except(*attributes_to_ignore) }.uniq }

    inconsistent_bands = unique_bands_by_index.select { |_, bands| bands.size > 1 }
    inconsistent_bands.each_key do |index|
      errors.add(:base, "Band at index #{index} is inconsistent across statements for the same active lead provider")
    end
  end
end
