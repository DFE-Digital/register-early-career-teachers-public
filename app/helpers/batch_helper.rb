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
          govuk_link_to('View', admin_appropriate_body_batch_path(batch.appropriate_body, batch))
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
end
