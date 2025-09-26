module AppropriateBodies
  module ProcessBatch
    class ActionJob < ProcessBatchJob
      # @return [AppropriateBodies::ProcessBatch::Action]
      def self.batch_service = Action
    end
  end
end
