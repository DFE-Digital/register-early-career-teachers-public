class Contract::BandCapacity < ApplicationRecord
  self.table_name = "contract_band_capacities"

  # Associations
  belongs_to :active_lead_provider

  has_many :contract_banded_fee_structure_bands,
           class_name: "Contract::BandedFeeStructure::Band",
           inverse_of: :contract_band_capacity # TODO: rename to capacity

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
  validate :declaration_boundaries_sequential_without_gaps,
           if: -> { min_declarations? && max_declarations? }
  validate :first_band_min_declarations_is_one

private

  def declaration_boundaries_sequential_without_gaps
    return unless active_lead_provider

    ordered_capacities = active_lead_provider_capacities.sort_by(&:min_declarations)

    return if ordered_capacities.each_cons(2).all? { |a, b| a.max_declarations + 1 == b.min_declarations }

    errors.add(:base, "Declaration boundaries must be sequential without gaps")
  end

  def first_band_min_declarations_is_one
    return unless active_lead_provider

    capacities = active_lead_provider_capacities

    return if capacities.min_by(&:min_declarations).min_declarations == 1

    errors.add(:base, "The first band's min declarations must be 1")
  end

  def active_lead_provider_capacities
    Contract::BandCapacity.where(active_lead_provider:).where.not(id: id || 0).to_a.push(self)
  end
end
