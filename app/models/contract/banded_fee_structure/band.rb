class Contract::BandedFeeStructure::Band < ApplicationRecord
  self.table_name = "contract_banded_fee_structure_bands"

  belongs_to :banded_fee_structure,
             class_name: "Contract::BandedFeeStructure"

  validates :priority, uniqueness: { scope: :banded_fee_structure_id }
  validates :priority,
            presence: { message: "Priority is required" },
            numericality: {
              greater_than: 0,
              only_integer: true,
              message: "Priority must be a number greater than zero"
            }
  validates :capacity,
            presence: { message: "Capacity is required" },
            numericality: {
              greater_than: 0,
              only_integer: true,
              message: "Capacity must be a number greater than zero"
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
  validate :priorities_are_sequential_without_gaps,
           if: -> { priority && capacity }

  def letter = ("A".ord + banded_fee_structure.bands.index(self)).chr

  def min_declarations
    banded_fee_structure
      .bands
      .select { it.priority < priority }
      .sum(&:capacity) + 1
  end

  def max_declarations
    min_declarations + capacity - 1
  end

private

  def sum_of_ratios_equals_one
    errors.add(:base, "Sum of ratios must equal 1") unless
      (output_fee_ratio + service_fee_ratio).to_d == 1.0.to_d
  end

  def priorities_are_sequential_without_gaps
    return unless banded_fee_structure

    ordered_bands = banded_fee_structure
      .bands
      .where.not(id:)
      .to_a
      .push(self)
      .sort_by(&:priority)

    return if ordered_bands.each_cons(2).all? { |a, b| a.priority + 1 == b.priority }

    errors.add(:base, "Priorities must be sequential without gaps")
  end
end
