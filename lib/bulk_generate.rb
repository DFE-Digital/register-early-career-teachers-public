# Select from known pre-prod TRNs and create 2 CSV files (for Claims and Actions)
# NB: TRS status cannot be guaranteed
class BulkGenerate
  def call
    export(headers: ::BatchRows::CLAIM_CSV_HEADINGS.values, rows: claim_rows, filename: 'tmp/bulk-claim.csv')
    export(headers: ::BatchRows::ACTION_CSV_HEADINGS.values, rows: action_rows, filename: 'tmp/bulk-action.csv')
  end

private

  def api_client
    @api_client ||= ::TRS::APIClient.new
  end

  def dataset
    Rails.root.join('spec/fixtures/pre-prod-trns.csv')
  end

  def trns
    @trns ||= CSV.read(dataset)
  end

  def ects
    @ects ||= trns.map do |trn, date_of_birth|
      status = api_client.find_teacher(trn:, date_of_birth:).present[:trs_induction_status]
      [trn, date_of_birth, status]
    rescue StandardError
      [trn, date_of_birth, 'API could not be contacted']
    end
  end

  def claim_rows
    ects.map do |trn, date_of_birth, status|
      [trn, date_of_birth, random_programme, random_start_date, status]
    end
  end

  def action_rows
    ects.map do |trn, date_of_birth, status|
      [trn, date_of_birth, random_end_date, random_term, random_outcome, status]
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
end
