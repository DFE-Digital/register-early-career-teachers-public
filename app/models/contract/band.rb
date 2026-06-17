# Allocated buckets with varying capacities.
# The first band (A) pays the most.
#
class Contract::Band < ApplicationRecord
  self.table_name = "contract_bands"

  # Associations
  belongs_to :active_lead_provider

  has_many :contract_banded_fee_structure_bands,
           class_name: "Contract::BandedFeeStructure::Band",
           inverse_of: :contract_band

  # Validations
  validates :active_lead_provider,
            presence: { message: "Active lead provider is required" }

  validates :allocation_order,
            presence: { message: "Allocation order is required" },
            numericality: {
              greater_than: 0,
              only_integer: true,
              message: "Allocation order must be a number greater than zero"
            }
  validates :capacity,
            presence: { message: "Capacity is required" },
            numericality: {
              greater_than: 0,
              only_integer: true,
              message: "Capacity must be a number greater than zero"
            }

  validate :allocation_orders_are_sequential_and_contiguous_from_one

private

  def allocation_orders_are_sequential_and_contiguous_from_one
    return unless active_lead_provider
    return unless allocation_order

    orders = active_lead_provider_bands_excluding_self.to_a.push(self).map(&:allocation_order)
    expected = (1..orders.max).to_a

    if orders.min != 1
      errors.add(:allocation_order, "The first band's allocation order must be 1")
    elsif orders.sort != expected
      errors.add(:allocation_order, "Allocation orders must be sequential without gaps")
    end
  end

  def active_lead_provider_bands_excluding_self
    Contract::Band.where(active_lead_provider:).where.not(id: id || 0)
  end
end
