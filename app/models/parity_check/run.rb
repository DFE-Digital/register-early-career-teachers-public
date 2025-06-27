module ParityCheck
  class Run < ApplicationRecord
    self.table_name = "parity_check_runs"

    after_commit -> { broadcast_run_states }

    has_many :requests, dependent: :destroy

    attribute :mode, default: -> { "concurrent" }

    validates :mode, presence: true, inclusion: { in: %w[concurrent sequential] }
    validates :state, uniqueness: true, if: -> { state == "in_progress" }

    scope :in_progress, -> { with_states(:in_progress) }
    scope :pending, -> { with_state(:pending) }
    scope :completed, -> { with_state(:completed).order(started_at: :desc) }

    state_machine :state, initial: :pending do
      state :in_progress do
        validates :started_at, presence: true
      end

      state :completed do
        validate :all_requests_are_completed
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

    def request_group_names
      requests.map { it.endpoint.group_name }.uniq
    end

    def rect_performance_gain_ratio
      ecf_times = requests.map(&:average_ecf_response_time_ms).compact
      rect_times = requests.map(&:average_rect_response_time_ms).compact

      return if (ecf_times + rect_times).none?

      ecf_average_response_time_ms = ecf_times.sum.fdiv(ecf_times.size)
      rect_average_response_time_ms = rect_times.sum.fdiv(rect_times.size)

      (ecf_average_response_time_ms.to_f / rect_average_response_time_ms).round(1)
    end

    def match_rate
      total_requests_with_all_responses_matching = requests.with_all_responses_matching.count
      total_requests = requests.count

      return 0 if total_requests.zero?

      (total_requests_with_all_responses_matching.to_f / total_requests * 100).round
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

    def broadcast_run_states
      locals = {
        in_progress_run: ParityCheck::Run.in_progress.first,
        completed_runs: ParityCheck::Run.completed,
        pending_runs: ParityCheck::Run.pending,
      }

      html = ::Migration::ParityChecksController.renderer.render(
        partial: "migration/parity_checks/runs_sidebar",
        locals:
      )

      broadcast_update_to :run_states, html:, target: :run_states
    end

  private

    def all_requests_are_completed
      errors.add(:requests, "Not all requests have been completed.") if requests.incomplete.any?
    end

    def calculate_progress
      total_request_count = requests.count

      return 0 if total_request_count.zero?

      completed_request_count = requests.completed.count

      (completed_request_count.to_f / total_request_count * 100).round
    end
  end
end
