class ActiveLeadProvider::Band < ApplicationRecord
  self.table_name = "active_lead_provider_bands"

  attr_accessor :allow_creation_when_contracted_or_after_contract_period_start

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

  validate :capacity_cannot_be_less_than_total_payment_declarations

  validate :bands_can_be_added_and_removed, on: :create, unless: :allow_creation_when_contracted_or_after_contract_period_start

  # Callbacks
  before_update :abort_update, unless: :last?
  before_destroy :abort_destruction, unless: :last?

  before_validation :assign_allocation_order,
                    on: :create,
                    if: -> { active_lead_provider.present? }

  before_destroy :abort_unless_bands_can_be_added_and_removed

  delegate :bands_can_be_added_and_removed?, to: :active_lead_provider

  # @return [Integer, nil]
  def min_declarations
    return nil unless has_allocation_order?

    prior_capacity + 1
  end

  # @return [Integer, nil]
  def max_declarations
    return nil unless has_allocation_order?
    return capacity if first?

    min_declarations + capacity - 1
  end

  # @return [String] A, B, C...
  def letter
    ("A".ord + allocation_order - 1).chr
  end

  def last?
    active_lead_provider.bands.last == self
  end

  def editable?
    last?
  end

  def deletable?
    last? && bands_can_be_added_and_removed?
  end

private

  # Read-only
  def assign_allocation_order
    self.allocation_order = active_lead_provider.bands.count + 1
  end

  # @return [Boolean]
  def first?
    allocation_order == 1
  end

  def abort_update
    errors.add(:base, "Only the last band can be updated")
    throw(:abort)
  end

  def abort_destruction
    errors.add(:base, "Only the last band can be destroyed")
    throw(:abort)
  end

  def abort_unless_bands_can_be_added_and_removed
    bands_can_be_added_and_removed
    throw(:abort) if errors.any?
  end

  def bands_can_be_added_and_removed
    unless active_lead_provider.present? && bands_can_be_added_and_removed?
      errors.add(:base, "Bands cannot be added or deleted once a contract is in place or the contract period has begun")
    end
  end

  def capacity_cannot_be_less_than_total_payment_declarations
    return if active_lead_provider.blank?

    minimum_capacity = active_lead_provider.payment_declarations.count - prior_capacity
    minimum_capacity = 1 unless minimum_capacity.positive?

    if capacity.present? && capacity < minimum_capacity
      errors.add(:capacity, "Band #{letter} capacity must be at least #{minimum_capacity} to cover the existing payment declarations")
    end
  end

  # @return [Boolean]
  def has_allocation_order?
    allocation_order.present? && persisted?
  end

  # @return [Integer]
  def prior_capacity
    prior_bands.sum(&:capacity)
  end

  def prior_bands
    if active_lead_provider.association(:bands).loaded?
      active_lead_provider.bands.select { |band| band.allocation_order < allocation_order }
    else
      active_lead_provider.bands.where("allocation_order < ?", allocation_order)
    end
  end
end
