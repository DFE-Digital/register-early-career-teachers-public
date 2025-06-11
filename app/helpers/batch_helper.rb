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
        %w[1234567 2000-11-10 FIP 2025-05-17],
        %w[2345671 1987-03-29 CIP 2024-04-29],
        %w[3456712 1992-01-14 DIY 2025-02-03],
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

    govuk_tag(text: batch.batch_status, colour: colours[batch.batch_status.to_sym])
  end

  # @param batches [Array<PendingInductionSubmissionBatches>]
  def batch_list_table(batches)
    govuk_table(
      caption: 'Upload history',
      head: ['#', 'Type', 'Filename', 'Status'],
      rows: batches.map do |batch|
        link =
          case batch.batch_type
          when 'claim' then govuk_link_to(batch.id, ab_batch_claim_path(batch))
          when 'action' then govuk_link_to(batch.id, ab_batch_action_path(batch))
          else
            batch.id
          end

        [link, batch.batch_type, batch.filename, batch_status_tag(batch)]
      end
    )
  end

  # @param batch [PendingInductionSubmissionBatch]
  def batch_action_summary(batch)
    submissions = batch.pending_induction_submissions.without_errors

    govuk_list([
      "#{pluralize(submissions.pass.count, 'ECT')} with a passed induction",
      "#{pluralize(submissions.fail.count, 'ECT')} with a failed induction",
      "#{pluralize(submissions.release.count, 'ECT')} with a released outcome",
    ], type: :bullet)
  end

  # Temporary method helpful for debugging during development
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
        value: { text: batch.processed_rows.count }
      },
      {
        key: { text: 'Number of failures to download' },
        value: { text: batch.failed_submissions.count }
      },
      {
        key: { text: 'Number of ongoing induction periods with this AB' },
        value: { text: batch.ongoing_induction_periods.count }
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

  # Temporary method helpful for debugging during development
  def batch_processed_data_table(batch)
    govuk_table(
      caption: "Processed (#{batch.processed_rows.count} submissions)",
      head: batch.processed_headers,
      rows: batch.processed_rows
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

  # Temporary method helpful for debugging during development
  def batch_actions_induction_periods_table(batch)
    govuk_table(
      caption: "Last inductions (#{batch.submissions_with_induction_periods.count} periods)",
      head: ['TRN', 'First name', 'Last name', 'Induction period end date', 'Number of terms', 'Outcome'],
      rows: batch.submissions_with_induction_periods.map do |pending_induction_submission, induction_period|
        [
          pending_induction_submission.trn,
          pending_induction_submission.trs_first_name,
          pending_induction_submission.trs_last_name,
          induction_period&.finished_on&.to_fs(:iso8601) || '-',
          induction_period&.number_of_terms&.to_s || '-',
          (induction_period&.outcome || '-')
        ]
      end
    )
  end

  # Temporary method helpful for debugging during development
  def batch_claims_induction_periods_table(batch)
    govuk_table(
      caption: "Last inductions (#{batch.submissions_with_induction_periods.count} periods)",
      head: ['TRN', 'First name', 'Last name', 'Induction programme', 'Induction period start date', 'Outcome'],
      rows: batch.submissions_with_induction_periods.map do |pending_induction_submission, induction_period|
        [
          pending_induction_submission.trn,
          pending_induction_submission.trs_first_name,
          pending_induction_submission.trs_last_name,
          induction_period&.induction_programme&.to_s || '-',
          induction_period&.started_on&.to_fs(:iso8601) || '-',
          (induction_period&.outcome || '-')
        ]
      end
    )
  end
end
