module ParityCheck
  class Run < ApplicationRecord
    self.table_name = "parity_check_runs"

    has_many :requests, dependent: :destroy

    attribute :mode, default: -> { :concurrent }

    validates :mode, presence: true, inclusion: { in: %w[concurrent sequential] }
    validates :state, uniqueness: true, if: -> { state == "in_progress" }

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

    def progress
      @progress ||= calculate_progress
    end

    def estimated_completion_at
      return nil unless in_progress? && requests.any? && progress.positive?

      current_runtime = Time.current - started_at
      estimated_runtime = current_runtime / (progress.to_f / 100)
      started_at + estimated_runtime
    end

  private

    def calculate_progress
      total_request_count = requests.count

      return 0 if total_request_count.zero?

      completed_request_count = requests.completed.count

      (completed_request_count.to_f / total_request_count * 100).round
    end
  end
end
