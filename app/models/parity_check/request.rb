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
    scope :incomplete, -> { without_state(:completed, :failed) }
    scope :failed, -> { with_state(:failed) }
    scope :queued_or_in_progress, -> { with_states(:queued, :in_progress) }
    scope :with_method, ->(method:) { joins(:endpoint).where(endpoint: { method: }) }
    scope :with_all_responses_matching, -> { joins(:responses).where.not(id: ParityCheck::Response.different.pluck(:request_id)).distinct }
    scope :with_lead_provider, ->(lead_provider) { where(lead_provider:) }

    delegate :description, :human_readable_url, :method, to: :endpoint

    state_machine :state, initial: :pending do
      state :queued

      state :in_progress do
        validates :started_at, presence: true
      end

      state :completed do
        validates :completed_at, comparison: { greater_than_or_equal_to: :started_at }
        validates :responses, presence: true
      end

      state :failed

      event :queue do
        transition [:pending] => :queued
      end

      event :start do
        transition [:queued] => :in_progress
      end

      event :complete do
        transition [:in_progress] => :completed
      end

      event :halt do
        transition [:in_progress] => :failed
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

    def pretty_json(ugly_json)
      JSON.pretty_generate(ugly_json)
    end

    def response_body_ids_different?
      responses.any?(&:body_ids_different?)
    end

    def response_body_ids_matching?
      !response_body_ids_different?
    end

    def ecf_response_body_ids
      responses.map(&:ecf_body_ids).flatten.sort
    end

    def rect_response_body_ids
      responses.map(&:rect_body_ids).flatten.sort
    end

    def ecf_only_response_body_ids
      ecf_response_body_ids - rect_response_body_ids
    end

    def rect_only_response_body_ids
      rect_response_body_ids - ecf_response_body_ids
    end
  end
end
