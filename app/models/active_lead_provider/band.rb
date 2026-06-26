class ActiveLeadProvider::Band < ApplicationRecord
  self.table_name = "active_lead_provider_bands"

  attr_readonly :allocation_order

  # Associations
  belongs_to :active_lead_provider

  has_many :band_terms,
           class_name: "Contract::BandedFeeStructure::BandTerm",
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

  # Callbacks
  before_update :abort_update, unless: :last?
  before_destroy :abort_destruction, unless: :last?
  before_validation :assign_allocation_order,
                    on: :create,
                    if: -> { active_lead_provider.present? }

  # @return [Integer, nil]
  def min_declarations
    return nil unless has_allocation_order?

    active_lead_provider.bands.where("allocation_order < ?", allocation_order).sum(:capacity) + 1
  end

  # @return [Integer, nil]
  def max_declarations
    return nil unless has_allocation_order?
    return capacity if first?

    min_declarations + capacity - 1
  end

private

  # Read-only
  def assign_allocation_order
    self.allocation_order = active_lead_provider.bands.count + 1
  end

  def abort_update
    errors.add(:base, "Only the last band can be updated")
    throw(:abort)
  end

  def abort_destruction
    errors.add(:base, "Only the last band can be destroyed")
    throw(:abort)
  end

  # @return [Boolean]
  def has_allocation_order?
    allocation_order.present? && persisted?
  end

  # @return [Boolean]
  def first?
    allocation_order == 1
  end

  # @return [Boolean]
  def last?
    active_lead_provider.bands.last == self
  end
end
