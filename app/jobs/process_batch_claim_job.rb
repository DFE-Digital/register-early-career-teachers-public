class ProcessBatchClaimJob < ProcessBatchJob
  # @return [AppropriateBodies::ProcessBatch::Claim]
  def self.batch_service
    AppropriateBodies::ProcessBatch::Claim
  end
end
