module Events
  class ReactToEventJob < ApplicationJob
    queue_as :default

    self.enqueue_after_transaction_commit = false

    discard_on ActiveJob::DeserializationError

    def perform(reactor:, event:)
      reactor.constantize.react_to!(event)
    end
  end
end
