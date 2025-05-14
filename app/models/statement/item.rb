class Statement::Item < ApplicationRecord
  belongs_to :statement

  state_machine :state, initial: :eligible do
    state :eligible
    state :payable
    state :paid
    state :voided
    state :ineligible
    state :awaiting_clawback
    state :clawed_back

    event :mark_as_payable do
      transition [:eligible] => :payable
    end

    event :mark_as_paid do
      transition [:payable] => :paid
    end

    event :mark_as_voided do
      transition %i[eligible payable] => :voided
    end

    event :mark_as_awaiting_clawback do
      transition [:paid] => :awaiting_clawback
    end

    event :mark_as_clawed_back do
      transition [:awaiting_clawback] => :clawed_back
    end

    event :mark_as_ineligible do
      transition [:eligible] => :ineligible
    end

    event :revert_to_eligible do
      transition [:payable] => :eligible
    end
  end
end
