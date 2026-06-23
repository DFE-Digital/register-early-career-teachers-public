class Contract::BandedFeeStructure::BandTerm < ApplicationRecord
  self.table_name = "contract_banded_fee_structure_band_terms"

  # Associations
  belongs_to :banded_fee_structure,
             class_name: "Contract::BandedFeeStructure"

  # TODO: enforce "null: false" for active_lead_provider_band_id and remove optional
  belongs_to :band,
             class_name: "ActiveLeadProvider::Band",
             optional: true

  # Validations

  # DEPRECATE
  validates :min_declarations,
            presence: { message: "Min declarations is required" },
            numericality: {
              greater_than: 0,
              only_integer: true,
              message: "Min declarations must be a number greater than zero"
            }
  # DEPRECATE
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
  # DEPRECATE
  validate :declaration_boundaries_sequential_without_gaps,
           if: -> { min_declarations? && max_declarations? }
  # DEPRECATE
  validate :first_band_min_declarations_is_one
  validate :band_consistency_across_active_lead_provider

  def letter = ("A".ord + banded_fee_structure.band_terms.index(self)).chr

  # TODO: DEPRECATE Contract::BandedFeeStructure::BandTerm#capacity
  def capacity
    max_declarations - min_declarations + 1
  end

private

  def sum_of_ratios_equals_one
    errors.add(:base, "Sum of ratios must equal 1") unless
      (output_fee_ratio + service_fee_ratio).to_d == 1.0.to_d
  end

  # DEPRECATE
  def first_band_min_declarations_is_one
    first_band_term = banded_fee_structure&.band_terms&.first || self

    return if first_band_term.min_declarations == 1

    errors.add(:min_declarations, "The first band's min declarations must be 1")
  end

  # DEPRECATE
  def declaration_boundaries_sequential_without_gaps
    return unless banded_fee_structure

    ordered_terms = banded_fee_structure
      .band_terms
      .where.not(id:)
      .to_a
      .push(self)
      .sort_by(&:min_declarations)

    return if ordered_terms.each_cons(2).all? { |a, b| a.max_declarations + 1 == b.min_declarations }

    errors.add(:base, "Declaration boundaries must be sequential without gaps")
  end

  # As the banded calculations take into account previous statements for
  # the same active lead provider, we need to ensure that the bands remain
  # consistent across all contracts associated with the same active lead provider.
  def band_consistency_across_active_lead_provider
    active_lead_provider = banded_fee_structure&.contract&.active_lead_provider
    return unless active_lead_provider

    band_terms_for_active_lead_provider = self.class
        .joins(banded_fee_structure: { contract: :active_lead_provider })
        .where(contracts: { active_lead_provider: })
        .where.not(id:)
        .to_a
        .push(self)

    attributes_to_ignore = %w[id banded_fee_structure_id created_at updated_at band_id].freeze
    unique_band_terms_by_index = band_terms_for_active_lead_provider
      .group_by { it.banded_fee_structure.band_terms.index(it) || it.banded_fee_structure.band_terms.count }
      .transform_values { |band_terms| band_terms.map { it.attributes.except(*attributes_to_ignore) }.uniq }

    inconsistent_band_terms = unique_band_terms_by_index.select { |_, band_terms| band_terms.size > 1 }

    inconsistent_band_terms.each_key do |index|
      errors.add(:base, "Band at index #{index} is inconsistent across statements for the same active lead provider")
    end
  end
end
