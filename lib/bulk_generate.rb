# Source TRNs and DoBs to create valid CSV files for Bulk Claim/Action journeys
# NB: TRS status cannot be guaranteed
class BulkGenerate
  # @param trs [Boolean] Enable TRS lookup for induction status
  # @param trn_csv_file [String] Source input relative file path
  # @param period_min_interval [Integer] Fewest possible days in an induction period
  # @param claim_csv_headings [Array<String>] Claim template column headings
  # @param action_csv_headings [Array<String>] Action template column headings
  # @param claim_csv_file [String] Claim output relative file path
  # @param action_csv_file [String] Action output relative file path
  def initialize(
    trs: true,
    trn_csv_file: 'spec/fixtures/pre-prod-trns.csv',
    period_min_interval: 60,
    claim_csv_headings: ::BatchRows::CLAIM_CSV_HEADINGS.values,
    action_csv_headings: ::BatchRows::ACTION_CSV_HEADINGS.values,
    claim_csv_file: 'tmp/bulk-claim.csv',
    action_csv_file: 'tmp/bulk-action.csv'
  )
    @trs = trs
    @api_client = ::TRS::APIClient.build
    @dataset = Rails.root.join(trn_csv_file)
    @trns = CSV.read(dataset, skip_lines: /^#/)
    @period_min_interval = period_min_interval
    @claim_headers = claim_csv_headings
    @action_headers = action_csv_headings
    @claim_filename = claim_csv_file
    @action_filename = action_csv_file
  end

  attr_reader :trs, :api_client, :dataset, :trns, :period_min_interval,
              :claim_headers, :action_headers,
              :claim_filename, :action_filename

  # @return [nil]
  def call(verbose: false)
    export(headers: claim_headers, rows: claim_rows, filename: claim_filename)
    export(headers: action_headers, rows: action_rows, filename: action_filename)

    if verbose
      ects.group_by { |_trn, _date_of_birth, status| status }.sort.each do |status, group|
        puts "#{group.size} - #{status}"
      end
      puts "========================="
      puts "#{ects.size} - Total"
    end
  end

  # @return [Array<Array>]
  def claim_rows
    ects.map do |trn, date_of_birth, status|
      [trn, date_of_birth, random_programme, random_start_date, status]
    end
  end

  # @return [Array<Array>]
  def action_rows
    ects.map do |trn, date_of_birth, status|
      [trn, date_of_birth, random_end_date, random_term, random_outcome, status]
    end
  end

private

  # @return [Array<Array>]
  def ects
    @ects ||= trns.map do |trn, date_of_birth|
      status = if trs
                 api_client.find_teacher(trn:, date_of_birth:).present[:trs_induction_status]
               else
                 'TRS query disabled'
               end
      [trn, date_of_birth, status]
    rescue StandardError
      [trn, date_of_birth, 'API could not be contacted']
    end
  end

  # @return [Date]
  def random_start_date
    rand((period_min_interval + 1)..(period_min_interval * 2)).days.ago.to_date
  end

  # @return [Date]
  def random_end_date
    rand(1..period_min_interval).days.ago.to_date
  end

  # @return [String]
  def random_programme
    ::TRAINING_PROGRAMME.values.sample
  end

  # @return [Float]
  def random_term
    rand(0.0..16.0).round(1)
  end

  # TODO: "release" is not yet a valid outcome enum value
  # @return [String]
  def random_outcome
    %w[pass fail release].sample
  end

  # @param headers [Array<String>]
  # @param rows [Array<Array>]
  # @param filename [String]
  # @return [Array<Array>]
  def export(headers:, rows:, filename:)
    CSV.open(Rails.root.join(filename), 'w') do |csv|
      csv << headers
      rows.each { |row| csv << row }
    end
  end
end
