# The PendingInductionSubmissionBatch#batch_status "failed" is only used for internal
# errors and should not occur in production.
#
# Occasionally, we may decide or need to remove these failed batches if they exist.

PendingInductionSubmissionBatch.transaction do
  PendingInductionSubmissionBatch.failed.delete_all
end
