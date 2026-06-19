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

  validate :first_band_allocation_order_is_one, on: :create

  # Callbacks
  before_validation :assign_allocation_order,
                    on: :create,
                    if: -> { active_lead_provider.present? && allocation_order.blank? }

  # @return [Boolean]
  def editable?
    active_lead_provider.bands.last == self
  end

  # @return [Boolean]
  def allocated?
    allocation_order.present? && persisted?
  end

  # @return [Boolean]
  def first_band?
    return false unless allocated?

    allocation_order == 1
  end

  def previous_band
    return nil unless allocated?
    return nil if first_band?

    active_lead_provider.bands.find_by(allocation_order: allocation_order - 1)
  end

  def min_declarations
    return nil unless allocated?
    return 1 if first_band?

    previous_band.max_declarations + 1
  end

  def max_declarations
    return nil unless allocated?
    return capacity if first_band?

    min_declarations + capacity - 1
  end

private

  def assign_allocation_order
    self.allocation_order = active_lead_provider.bands.count + 1
  end

  def first_band_allocation_order_is_one
    return unless allocation_order && allocation_order > 1
    return if active_lead_provider.bands.exists?

    errors.add(:allocation_order, "The first band's allocation order must be 1")
  end
end
