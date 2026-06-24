class ActiveLeadProvider::Band < ApplicationRecord
  self.table_name = "active_lead_provider_bands"

  attr_readonly :allocation_order

  # Associations
  belongs_to :active_lead_provider

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

  # Callbacks
  before_update :prevent_update, unless: :last?
  before_destroy :abort_destruction, unless: :last?
  before_validation :assign_allocation_order,
                    on: :create,
                    if: -> { active_lead_provider.present? }

  # @return [Integer, nil]
  def min_declarations
    return nil unless has_allocation_order?
    return 1 if first?

    previous_band.max_declarations + 1
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

  def prevent_update
    raise ActiveRecord::RecordNotSaved.new("Only the last band can be updated", self)
  end

  def abort_destruction
    raise ActiveRecord::RecordNotDestroyed.new("Only the last band can be destroyed", self)
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

  # @return [ActiveLeadProvider::Band]
  def previous_band
    return nil unless has_allocation_order?
    return nil if first?

    active_lead_provider.bands.find_by(allocation_order: allocation_order - 1)
  end
end
