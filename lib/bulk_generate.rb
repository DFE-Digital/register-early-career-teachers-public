# Select from known pre-prod TRNs and create 2 CSV files (for Claims and Actions)
# NB: randomised and limited to maximum row size, TRS status cannot be guaranteed
class BulkGenerate
  def call
    export(headers: columns_for(claim_template), rows: claim_rows, filename: 'tmp/bulk-max-claim.csv')
    export(headers: columns_for(action_template), rows: action_rows, filename: 'tmp/bulk-max-action.csv')
  end

private

  def dataset
    Rails.root.join('spec/fixtures/pre-prod-trns.csv')
  end

  def trns
    @trns ||= CSV.read(dataset)
  end

  def ects
    @ects ||= trns.shuffle.take(sample_size)
  end

  def columns_for(template)
    template.values.reject { |v| v.match?(/error/i) }
  end

  def claim_rows
    ects.map do |trn, dob|
      [trn, dob, random_programme, random_start_date]
    end
  end

  def action_rows
    ects.map do |trn, dob|
      [trn, dob, random_end_date, random_term, random_outcome]
    end
  end

  def random_start_date
    61.days.ago.to_date - rand(1..60)
  end

  def random_end_date
    Time.zone.today - rand(1..60)
  end

  def random_programme
    %w[cip fip diy].sample
  end

  def random_term
    rand(0.0..16.0).round(1)
  end

  def random_outcome
    %w[pass fail release].sample
  end

  def export(headers:, rows:, filename:)
    CSV.open(Rails.root.join(filename), 'w') do |csv|
      csv << headers
      rows.each { |row| csv << row }
    end
  end

  def sample_size
    ::AppropriateBodies::ProcessBatchForm::MAX_ROW_SIZE
  end

  def claim_template
    ::BatchRows::CLAIM_CSV_HEADINGS
  end

  def action_template
    ::BatchRows::ACTION_CSV_HEADINGS
  end
end
