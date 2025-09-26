module AppropriateBodies
  module ProcessBatch
    class ClaimJob < ProcessBatchJob
      # @return [AppropriateBodies::ProcessBatch::Claim]
      def self.batch_service = Claim
    end
  end
end
