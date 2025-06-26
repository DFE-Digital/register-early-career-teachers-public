module ParityCheck
  class Request < ApplicationRecord
    self.table_name = "parity_check_requests"

    belongs_to :run
    belongs_to :lead_provider
    belongs_to :endpoint
    has_many :responses, dependent: :destroy

    validates :lead_provider, presence: true
    validates :run, presence: true
    validates :endpoint, presence: true

    scope :pending, -> { with_state(:pending) }
    scope :completed, -> { with_state(:completed) }
    scope :queued_or_in_progress, -> { with_states(:queued, :in_progress) }
    scope :with_method, ->(method:) { joins(:endpoint).where(endpoint: { method: }) }

    state_machine :state, initial: :pending do
      state :queued

      state :in_progress do
        validates :started_at, presence: true
      end

      state :completed do
        validates :completed_at, comparison: { greater_than_or_equal_to: :started_at }
      end

      event :queue do
        transition [:pending] => :queued
      end

      event :start do
        transition [:queued] => :in_progress
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
