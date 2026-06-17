class ActiveLeadProvider::Band < ApplicationRecord
  self.table_name = "active_lead_provider_bands"

  attr_readonly :allocation_order

  # Associations
  belongs_to :active_lead_provider, optional: false

  has_many :terms,
           class_name: "Contract::BandedFeeStructure::Band", # TODO: rename to BandTerms
           inverse_of: :band

  # Validations
  validates :active_lead_provider,
            presence: { message: "Choose a lead provider" }

  validates :allocation_order,
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

  before_validation :assign_allocation_order,
                    on: :create,
                    if: -> { allocation_order.blank? }

private

  def assign_allocation_order
    self.allocation_order = self.class.where(active_lead_provider:).maximum(:allocation_order).to_i + 1
  end

  def allocation_orders_are_sequential_and_contiguous_from_one
    return unless active_lead_provider && allocation_order

    siblings = self.class.where(active_lead_provider:).excluding(self)
    orders = siblings.pluck(:allocation_order).append(allocation_order).sort
    expected = (1..orders.size).to_a

    return if orders == expected

    errors.add(:allocation_order, "The first band's allocation order must be 1") if orders.first != 1
    errors.add(:allocation_order, "The allocation order should be #{expected.last}") if expected.last != allocation_order
  end
end
