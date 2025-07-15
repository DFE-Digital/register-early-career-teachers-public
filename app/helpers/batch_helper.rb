module BatchHelper
  def batch_example_action
    govuk_table(
      caption: "Your file needs to look like this example",
      head: BatchRows::ACTION_CSV_HEADINGS.values.reject { |v| v.match?(/error/i) },
      rows: [
        %w[1234567 2000-11-10 2025-04-17 2.5 pass],
        %w[2345671 1987-03-29 2024-10-31 10 fail],
        %w[3456712 1992-01-14 2025-06-30 16 release],
      ]
    )
  end

  def batch_example_claim
    govuk_table(
      caption: "Your file needs to look like this example",
      head: BatchRows::CLAIM_CSV_HEADINGS.values.reject { |v| v.match?(/error/i) },
      rows: [
        %w[1234567 2000-11-10 provider-led 2025-05-17],
        %w[3456712 1992-01-14 school-led 2025-02-03],
      ]
    )
  end

  # @param batch [PendingInductionSubmissionBatch]
  def batch_status_tag(batch)
    colours = {
      pending: 'grey',
      processing: 'blue',
      processed: 'turquoise',
      completing: 'purple',
      completed: 'green',
      failed: 'red'
    }

    govuk_tag(text: batch.batch_status.titleize, colour: colours[batch.batch_status.to_sym])
  end

  # @param batch [PendingInductionSubmissionBatch]
  def batch_type_tag(batch)
    colours = {
      claim: 'light-blue',
      action: 'purple'
    }

    govuk_tag(text: batch.batch_type.titleize, colour: colours[batch.batch_type.to_sym])
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
        [batch.id.to_s, batch.file_name, batch_status_tag(batch), batch_link(batch)]
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
          batch_type_tag(batch),
          batch_status_tag(batch),
          batch.file_name || '-',
          batch.created_at.to_fs(:govuk),
          batch.tally[:uploaded_count].to_s,
          batch.tally[:processed_count].to_s,
          batch.tally[:errored_count].to_s,
          govuk_link_to('View', admin_bulk_batch_path(batch))
        ]
      end
    )
  end

  # @param batch [PendingInductionSubmissionBatch]
  def batch_action_summary(batch)
    govuk_list([
      "#{pluralize(batch.tally[:passed_count], 'ECT')} with a passed induction",
      "#{pluralize(batch.tally[:failed_count], 'ECT')} with a failed induction",
      "#{pluralize(batch.tally[:released_count], 'ECT')} with a released outcome",
    ], type: :bullet)
  end

  # @param batch [PendingInductionSubmissionBatch] metrics of a completed batch
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
        value: { text: batch_type_tag(batch) }
      },
      {
        key: { text: 'Batch error' },
        value: { text: batch.error_message }
      },
      {
        key: { text: 'File name' },
        value: { text: batch.file_name }
      },
      {
        key: { text: 'Number of CSV rows' },
        value: { text: batch.tally[:uploaded_count] }
      },
      {
        key: { text: 'Number of processed submission records' },
        value: { text: batch.tally[:processed_count] }
      },
      {
        key: { text: 'Number of submissions with errors' },
        value: { text: batch.tally[:errored_count] }
      },
      {
        key: { text: 'Number of submissions without errors' },
        value: { text: batch.recorded_count }
      },
    ])
  end

  # @param batch [PendingInductionSubmissionBatch]
  def batch_raw_data_table(batch)
    govuk_table(
      caption: "Uploaded CSV data (#{batch.rows.count} rows)",
      head: batch.row_headings.values,
      rows: batch.rows
    )
  end

  # @param batch [PendingInductionSubmissionBatch]
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

  # Temporary method helpful for debugging during development
  def batch_download_data_table(batch)
    govuk_table(
      caption: "Downloadable bad CSV data (#{batch.failed_submissions.count} rows)",
      head: batch.row_headings.values,
      rows: batch.failed_submissions
    )
  end

  # @param batch [PendingInductionSubmissionBatch]
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

  # @param batch [PendingInductionSubmissionBatch]
  def batch_claims_induction_periods_table(batch)
    valid_submissions = batch.pending_induction_submissions.without_errors

    govuk_table(
      caption: "Valid claim submissions (#{valid_submissions.count} records)",
      head: ['TRN', 'Date of birth', 'Induction programme', 'Start date'],
      rows: valid_submissions.map do |submission|
        induction_programme = if Rails.application.config.enable_bulk_claim
                                ::TRAINING_PROGRAMME.fetch(submission.training_programme.to_sym, '-')
                              else
                                ::INDUCTION_PROGRAMMES.fetch(submission.induction_programme.to_sym, '-')
                              end
        [
          submission.trn,
          submission.date_of_birth&.to_fs(:govuk) || '-',
          induction_programme,
          submission.started_on&.to_fs(:govuk) || '-'
        ]
      end
    )
  end
end
