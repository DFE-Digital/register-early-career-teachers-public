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
  validates :data, presence: true

  # Callbacks
  after_update_commit :update_batch_progress, if: :action?

  # @return [Boolean]
  def no_valid_data?
    pending_induction_submissions.count == pending_induction_submissions.with_errors.count
  end

  # @return [Float]
  def progress
    pending_induction_submissions.count.to_f / data.count * 100
  end

private

  # guard clause displays throbber for the duration of processing
  # removing it can display percentage progress
  def update_batch_progress
    return if progress.between?(1, 99)

    broadcast_update_to(
      "batch_progress_stream_#{id}",
      target: "batch_progress_target_#{id}",
      partial: "appropriate_bodies/process_batch/#{batch_type.pluralize}/#{batch_status}",
      locals: { batch: self }
    )
  end
end
