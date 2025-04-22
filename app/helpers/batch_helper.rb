module BatchHelper
  def batch_progress_card(pending_induction_submission_batch)
    govuk_summary_list(card: { title: 'Progress' }, rows: [
      {
        key: { text: 'Appropriate Body' },
        value: { text: pending_induction_submission_batch.appropriate_body.name }
      },
      {
        key: { text: 'Batch ID' },
        value: { text: pending_induction_submission_batch.id }
      },
      {
        key: { text: 'Batch status' },
        value: { text: govuk_tag(text: pending_induction_submission_batch.batch_status) }
      },
      {
        key: { text: 'Batch type' },
        value: { text: govuk_tag(text: pending_induction_submission_batch.batch_type) }
      },
      {
        key: { text: 'Batch error' },
        value: { text: pending_induction_submission_batch.error_message }
      },
      {
        key: { text: 'Number of CSV rows' },
        value: { text: pending_induction_submission_batch.rows.count }
      },
      {
        key: { text: 'Number of processed submission records' },
        value: { text: pending_induction_submission_batch.processed_rows.count }
      },
      {
        key: { text: 'Number of failures to download' },
        value: { text: pending_induction_submission_batch.failed_submissions.count }
      },
      {
        key: { text: 'Number of ongoing induction periods with this AB' },
        value: { text: pending_induction_submission_batch.ongoing_induction_periods.count }
      },
    ])
  end

  def batch_raw_data_table(pending_induction_submission_batch)
    govuk_table(
      caption: "Uploaded CSV data (#{pending_induction_submission_batch.rows.count} rows)",
      head: pending_induction_submission_batch.row_headings.values,
      rows: pending_induction_submission_batch.rows
    )
  end

  def batch_processed_data_table(pending_induction_submission_batch)
    govuk_table(
      caption: "Processed (#{pending_induction_submission_batch.processed_rows.count} submissions)",
      head: pending_induction_submission_batch.processed_headers,
      rows: pending_induction_submission_batch.processed_rows
    )
  end

  def batch_download_data_table(pending_induction_submission_batch)
    govuk_table(
      caption: "Downloadable bad CSV data (#{pending_induction_submission_batch.failed_submissions.count} rows)",
      head: pending_induction_submission_batch.row_headings.values,
      rows: pending_induction_submission_batch.failed_submissions
    )
  end
end
