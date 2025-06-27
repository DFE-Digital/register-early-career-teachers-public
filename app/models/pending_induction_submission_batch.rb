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

  # @return [Boolean]
  def no_valid_data?
    pending_induction_submissions.count == pending_induction_submissions.with_errors.count
  end

  # TODO: refactor and merge with no_valid_data?
  # @return [Boolean]
  def errored?
    errored_count.to_i.positive?
  end

  # @return [Float]
  def progress
    pending_induction_submissions.count.to_f / data.count * 100
  end

  # @return [Integer] claim or pass + fail + release count
  def recorded_count
    processed_count.to_i - errored_count.to_i
  end

  # @return [Hash{Symbol => Integer}]
  def tally
    {
      uploaded_count: completed? ? uploaded_count : rows.count,
      processed_count: completed? ? processed_count : pending_induction_submissions.count,
      errored_count: completed? ? errored_count : pending_induction_submissions.with_errors.count,
      released_count: completed? ? released_count : pending_induction_submissions.release.count,
      failed_count: completed? ? failed_count : pending_induction_submissions.fail.count,
      passed_count: completed? ? passed_count : pending_induction_submissions.pass.count,
      claimed_count: completed? ? claimed_count : pending_induction_submissions.claim.count
    }
  end

  # @return [Boolean] record metrics before successful submissions are pruned
  def tally!
    update(
      uploaded_count: rows.count,
      processed_count: pending_induction_submissions.count,
      errored_count: pending_induction_submissions.with_errors.count,
      released_count: pending_induction_submissions.release.count,
      failed_count: pending_induction_submissions.fail.count,
      passed_count: pending_induction_submissions.pass.count,
      claimed_count: pending_induction_submissions.claim.count
    )
  end

  # @return [Boolean] purge PII when all submissions have been successful
  def redact!
    update(data: []) if pending_induction_submissions.with_errors.count.zero?
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
