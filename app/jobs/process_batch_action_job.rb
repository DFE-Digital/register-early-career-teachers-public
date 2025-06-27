class ProcessBatchActionJob < ProcessBatchJob
  # @return [AppropriateBodies::ProcessBatch::Action]
  def self.batch_service
    AppropriateBodies::ProcessBatch::Action
  end
end
