module OverlappingZeroLengthSiblings
  extend ActiveSupport::Concern

  def overlap_siblings
    return self.class.none if zero_length?

    siblings.where("#{self.class.table_name}.finished_on IS NULL OR #{self.class.table_name}.started_on <> #{self.class.table_name}.finished_on")
  end

  private

  def zero_length?
    started_on.present? && started_on == finished_on
  end
end
