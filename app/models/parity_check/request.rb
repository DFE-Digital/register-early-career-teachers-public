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
    scope :incomplete, -> { without_state(:completed) }
    scope :queued_or_in_progress, -> { with_states(:queued, :in_progress) }
    scope :with_method, ->(method:) { joins(:endpoint).where(endpoint: { method: }) }
    scope :with_all_responses_matching, -> { joins(:responses).where.not(id: ParityCheck::Response.different.pluck(:request_id)).distinct }
    scope :with_lead_provider, ->(lead_provider) { where(lead_provider:) }

    state_machine :state, initial: :pending do
      state :queued

      state :in_progress do
        validates :started_at, presence: true
      end

      state :completed do
        validates :completed_at, comparison: { greater_than_or_equal_to: :started_at }
        validates :responses, presence: true
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

      after_transition any => :completed do |instance|
        instance.run.broadcast_run_states
      end
    end

    def rect_performance_gain_ratio
      ratios = responses.map(&:rect_performance_gain_ratio).compact

      return if ratios.empty?

      ratios.sum.fdiv(ratios.size).round(1)
    end

    def match_rate
      rates = responses.map(&:match_rate).compact

      return if rates.empty?

      rates.sum.fdiv(rates.size).round
    end
  end
end
