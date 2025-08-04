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

  # @param batches [Array<PendingInductionSubmissionBatch>]
  def batch_list_table(batches)
    govuk_table(
      caption: 'Upload history',
      head: ['Reference', 'File name', 'Status', 'Action'],
      rows: batches.map do |batch|
        [batch.id.to_s, batch.file_name, batch_status_tag(batch), batch_link(batch)]
      end
    )
  end

  # @param batches [Array<PendingInductionSubmissionBatch>]
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
          govuk_link_to('View', admin_appropriate_body_bulk_batch_path(batch.appropriate_body, batch))
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
  def batch_summary_card(batch)
    govuk_summary_list(card: { title: "#{batch.batch_type.titleize} ##{batch.id}" }, rows: [
      {
        key: { text: 'Status' },
        value: { text: batch_status_tag(batch) }
      },
      {
        key: { text: 'Uploaded' },
        value: { text: batch.created_at.to_fs(:govuk) }
      },
      {
        key: { text: 'File name' },
        value: { text: batch.file_name }
      },
      {
        key: { text: 'File size' },
        value: { text: batch.file_size }
      }
    ])
  end

  def batch_success_rate(batch)
    (batch.recorded_count / batch.tally[:uploaded_count].to_f * 100).round(1).to_s + '%'
  end

  # @param batch [PendingInductionSubmissionBatch]
  def batch_failed_rows_table(batch)
    rows = ::AppropriateBodies::ProcessBatch::Download.new(pending_induction_submission_batch: batch).to_a
    caption = "Errors (#{rows.count})"
    head = batch.row_headings.values

    govuk_table(caption:, head:, rows:)
  end

  # @param batch [PendingInductionSubmissionBatch]
  def batch_action_induction_periods_table(batch)
    caption = "Closed induction periods (#{batch.recorded_count})"
    head = ['Name', 'Induction period end date', 'Number of terms', 'Outcome']
    colours = { release: 'yellow', pass: 'green', fail: 'red' }
    inductions = InductionPeriod
        .eager_load(:teacher, :events)
        .where(events: { pending_induction_submission_batch_id: batch.id })
        .order(:trs_last_name)

    rows = inductions.map do |induction_period|
      outcome = induction_period.outcome || 'release'

      [
        govuk_link_to(teacher_full_name(induction_period.teacher), admin_teacher_path(induction_period.teacher)),
        induction_period.finished_on.to_fs(:govuk),
        induction_period.number_of_terms.to_s,
        govuk_tag(text: outcome.titleize, colour: colours[outcome.to_sym]),
      ]
    end

    govuk_table(caption:, head:, rows:)
  end

  # @param batch [PendingInductionSubmissionBatch]
  def batch_claim_induction_periods_table(batch)
    caption = "Opened induction periods (#{batch.recorded_count})"
    head = ['Name', 'Induction period start date', 'Induction programme']

    inductions = InductionPeriod
        .eager_load(:teacher, :events)
        .where(events: { pending_induction_submission_batch_id: batch.id })
        .order(:trs_last_name)

    rows = inductions.map do |induction_period|
      [
        govuk_link_to(teacher_full_name(induction_period.teacher), admin_teacher_path(induction_period.teacher)),
        induction_period.started_on.to_fs(:govuk),
        training_programme_name(induction_period.training_programme)
      ]
    end

    govuk_table(caption:, head:, rows:)
  end
end
