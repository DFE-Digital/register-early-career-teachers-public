module ParityCheck
  class Run < ApplicationRecord
    self.table_name = "parity_check_runs"

    has_many :requests

    attribute :mode, default: -> { :concurrent }

    validates :mode, presence: true, inclusion: { in: %w[concurrent sequential] }

    scope :in_progress, -> { with_states(:in_progress) }
    scope :pending, -> { with_state(:pending) }

    state_machine :state, initial: :pending do
      state :in_progress do
        validates :started_at, presence: true
      end

      state :completed do
        validates :completed_at, comparison: { greater_than_or_equal_to: :started_at }
      end

      event :in_progress do
        transition [:pending] => :in_progress
      end

      event :complete do
        transition [:in_progress] => :completed
      end

      before_transition any => :in_progress do |instance|
        instance.touch(:started_at)
      end

      before_transition any => :completed do |instance|
        instance.touch(:completed_at)
      end
    end
  end
end
