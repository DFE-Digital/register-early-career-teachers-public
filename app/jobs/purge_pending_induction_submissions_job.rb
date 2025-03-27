class PurgePendingInductionSubmissionsJob < ApplicationJob
  queue_as :default

  def perform
    PendingInductionSubmission.ready_for_deletion.delete_all
  end
end
