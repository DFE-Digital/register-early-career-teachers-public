module BatchHelper
  # @param batch [PendingInductionSubmissionBatch]
  def batch_status_tag(batch)
    colours = {
      pending: 'grey',
      processing: 'blue',
      processed: 'turquoise',
      completed: 'green',
      failed: 'red'
    }

    govuk_tag(text: batch.batch_status.titleize, colour: colours[batch.batch_status.to_sym])
  end

  # @param batch [PendingInductionSubmissionBatch]
  def batch_link(batch)
    paths = {
      claim: ab_batch_claim_path(batch),
      action: ab_batch_action_path(batch),
    }

    govuk_link_to('View', paths[batch.batch_type.to_sym])
  end

  # @param batches [Array<PendingInductionSubmissionBatches>]
  def batch_list_table(batches)
    govuk_table(
      caption: 'Upload history',
      head: ['Reference', 'File name', 'Status', 'Action'],
      rows: batches.map do |batch|
        [batch.id.to_s, batch.filename, batch_status_tag(batch), batch_link(batch)]
      end
    )
  end

  # @param batches [Array<PendingInductionSubmissionBatches>]
  def admin_batch_list_table(batches)
    govuk_table(
      head: [
        'Batch ID',
        'Appropriate Body',
        'Type',
        'Status',
        'Filename',
        'Created',
        'CSV Rows',
        'Processed',
        'Errors',
        'Action'
      ],
      rows: batches.map do |batch|
        [
          batch.id.to_s,
          batch.appropriate_body.name,
          govuk_tag(text: batch.batch_type, colour: batch.batch_type == 'claim' ? 'blue' : 'green'),
          batch_status_tag(batch),
          batch.filename || '-',
          batch.created_at.to_fs(:govuk),
          (batch.data&.count || 0).to_s,
          batch.pending_induction_submissions.count.to_s,
          batch.pending_induction_submissions.with_errors.count.to_s,
          govuk_link_to('View', admin_bulk_batch_path(batch))
        ]
      end
    )
  end

  # @param batch [PendingInductionSubmissionBatch]
  def batch_summary(batch)
    submissions = batch.pending_induction_submissions.without_errors

    govuk_list([
      "#{pluralize(submissions.pass.count, 'ECT')} with a passed induction",
      "#{pluralize(submissions.fail.count, 'ECT')} with a failed induction",
      "#{pluralize(submissions.release.count, 'ECT')} with a released outcome",
    ], type: :bullet)
  end

  def batch_progress_card(batch)
    govuk_summary_list(card: { title: 'Progress' }, rows: [
      {
        key: { text: 'Appropriate Body' },
        value: { text: batch.appropriate_body.name }
      },
      {
        key: { text: 'Batch ID' },
        value: { text: batch.id }
      },
      {
        key: { text: 'Batch status' },
        value: { text: batch_status_tag(batch) }
      },
      {
        key: { text: 'Batch type' },
        value: { text: govuk_tag(text: batch.batch_type, colour: 'yellow') }
      },
      {
        key: { text: 'Batch error' },
        value: { text: batch.error_message }
      },
      {
        key: { text: 'Number of CSV rows' },
        value: { text: batch.rows.count }
      },
      {
        key: { text: 'Number of processed submission records' },
        value: { text: batch.pending_induction_submissions.count }
      },
      {
        key: { text: 'Number of submissions with errors' },
        value: { text: batch.pending_induction_submissions.with_errors.count }
      },
      {
        key: { text: 'Number of submissions without errors' },
        value: { text: batch.pending_induction_submissions.without_errors.count }
      },
    ])
  end

  # Temporary method helpful for debugging during development
  def batch_raw_data_table(batch)
    govuk_table(
      caption: "Uploaded CSV data (#{batch.rows.count} rows)",
      head: batch.row_headings.values,
      rows: batch.rows
    )
  end

  def batch_processed_data_table(batch)
    govuk_table(
      caption: "Processed submissions (#{batch.pending_induction_submissions.count} total)",
      head: ['TRN', 'Date of birth', 'Status', 'Error messages'],
      rows: batch.pending_induction_submissions.map do |submission|
        [
          submission.trn,
          submission.date_of_birth&.to_fs(:govuk) || '-',
          submission.error_messages.any? ? 'Error' : 'Valid',
          submission.error_messages.join(', ').presence || '-'
        ]
      end
    )
  end

  def batch_download_data_table(batch)
    # error_submissions = batch.pending_induction_submissions.with_errors

    govuk_table(
      caption: "Downloadable bad CSV data (#{batch.failed_submissions.count} rows)",
      head: batch.row_headings.values,
      rows: batch.failed_submissions
    )
  end

  def batch_actions_induction_periods_table(batch)
    valid_submissions = batch.pending_induction_submissions.without_errors

    govuk_table(
      caption: "Valid action submissions (#{valid_submissions.count} records)",
      head: ['TRN', 'Date of birth', 'Finish date', 'Number of terms', 'Outcome'],
      rows: valid_submissions.map do |submission|
        [
          submission.trn,
          submission.date_of_birth&.to_fs(:govuk) || '-',
          submission.finished_on&.to_fs(:govuk) || '-',
          submission.number_of_terms&.to_s || '-',
          submission.outcome || '-'
        ]
      end
    )
  end

  def batch_claims_induction_periods_table(batch)
    valid_submissions = batch.pending_induction_submissions.without_errors

    govuk_table(
      caption: "Valid claim submissions (#{valid_submissions.count} records)",
      head: ['TRN', 'Date of birth', 'Induction programme', 'Start date'],
      rows: valid_submissions.map do |submission|
        [
          submission.trn,
          submission.date_of_birth&.to_fs(:govuk) || '-',
          submission.induction_programme || '-',
          submission.started_on&.to_fs(:govuk) || '-'
        ]
      end
    )
  end
end
