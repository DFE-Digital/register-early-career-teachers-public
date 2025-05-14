class Statement < ApplicationRecord
  belongs_to :lead_provider_active_period
  has_many :items
  has_many :adjustments

  state_machine :state, initial: :open do
    state :open
    state :payable
    state :paid

    event :mark_as_payable do
      transition [:open] => :payable
    end

    event :mark_as_paid do
      transition [:payable] => :paid
    end
  end
end
