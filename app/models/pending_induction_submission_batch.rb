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
end
