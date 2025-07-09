class PendingInductionSubmissionBatch < ApplicationRecord
  include BatchRows

  # @return [PendingInductionSubmissionBatch] type "claim"
  def self.new_claim_for(appropriate_body:, **)
    new(appropriate_body:, batch_type: 'claim', **)
  end

  # @return [PendingInductionSubmissionBatch] type "action"
  def self.new_action_for(appropriate_body:, **)
    new(appropriate_body:, batch_type: 'action', **)
  end

  # Enums
  enum :batch_status, {
    pending: 'pending',
    processing: 'processing',
    processed: 'processed',
    completing: 'completing',
    completed: 'completed',
    failed: 'failed'
  }

  enum :batch_type, {
    action: 'action',
    claim: 'claim'
  }

  # Associations
  belongs_to :appropriate_body
  has_many :pending_induction_submissions

  # Scopes
  scope :for_appropriate_body, ->(appropriate_body) { where(appropriate_body:) }

  # Validations
  validates :appropriate_body, presence: true
  validates :batch_status, presence: true
  validates :batch_type, presence: true
  validates :data, presence: true, if: :processed? # redact!

  # Callbacks
  after_update_commit :update_batch_progress

  # @return [Float] when processing
  def progress
    pending_induction_submissions.count.to_f / data.count * 100
  end

  # @return [Boolean] when processed
  def no_valid_data?
    pending_induction_submissions.count == pending_induction_submissions.with_errors.count
  end

  # @return [Boolean] when completing and completed
  def errored?
    if errored_count.nil?
      pending_induction_submissions.with_errors.count.positive?
    else
      errored_count.positive?
    end
  end

  # @return [Integer] when completing and completed
  def recorded_count
    if processed_count.nil?
      pending_induction_submissions.without_errors.count
    else
      processed_count - errored_count
    end
  end

  # @see BatchHelper#batch_action_summary
  # @return [Hash{Symbol => Integer}]
  def tally
    {
      uploaded_count: uploaded_count || rows.count,
      processed_count: processed_count || pending_induction_submissions.count,
      errored_count: errored_count || pending_induction_submissions.with_errors.count,
      released_count: released_count || pending_induction_submissions.released.count,
      failed_count: failed_count || pending_induction_submissions.failed.count,
      passed_count: passed_count || pending_induction_submissions.passed.count,
      claimed_count: claimed_count || pending_induction_submissions.claimed.count
    }
  end

  # @see [ProcessBatchJob#perform]
  # @return [Boolean] record metrics before successful submissions are pruned
  def tally!
    update(
      uploaded_count: rows.count,
      processed_count: pending_induction_submissions.count,
      errored_count: pending_induction_submissions.with_errors.count,
      released_count: pending_induction_submissions.released.count,
      failed_count: pending_induction_submissions.failed.count,
      passed_count: pending_induction_submissions.passed.count,
      claimed_count: pending_induction_submissions.claimed.count
    )
  end

  # @return [Boolean]
  def redactable?
    completed? && pending_induction_submissions.with_errors.count.zero?
  end

  # @return [nil, true] purge PII when all submissions have been successful
  def redact!
    update!(data: []) if redactable?
  end

private

  def update_batch_progress
    if processing?
      broadcast_update_to(
        "batch_progress_stream_#{id}",
        target: "batch_progress_percentage_#{id}",
        html: "#{progress.round}%"
      )
    else
      broadcast_update_to(
        "batch_progress_stream_#{id}",
        target: "batch_progress_status_#{id}",
        partial: "appropriate_bodies/process_batch/#{batch_type.pluralize}/#{batch_status}",
        locals: { batch: self }
      )
    end
  end
end
