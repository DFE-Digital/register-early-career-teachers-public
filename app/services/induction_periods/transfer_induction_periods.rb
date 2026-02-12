# Utility base class to select and amend inductions associated to the wrong appropriate body
#
module InductionPeriods
  class TransferInductionPeriods
    # @return [Array<String>]
    INDUCTION_TABLE_HEADERS = %w[
      id
      started_on
      finished_on
      appropriate_body_period_id
      teacher_id
    ].freeze

    # @return [Array<String>]
    EVENT_TABLE_HEADERS = %w[
      id
      induction_period.id
      induction_period.started_on
      induction_period.finished_on
      appropriate_body_period.id
      appropriate_body_period.name
      teacher.trn
      heading
      body
      author_name
      author_email
      author_type
    ].freeze

    attr_reader :current_appropriate_body,
                :new_appropriate_body,
                :cut_off_date,
                :inductions

    # @param from [AppropriateBodyPeriod] current owner
    # @param to [AppropriateBodyPeriod] new owner
    # @param on [Date] when the change of ownership occurred
    def initialize(from:, to:, on:)
      @current_appropriate_body = from
      @new_appropriate_body = to
      @cut_off_date = on
      @inductions = target_inductions
    end

    def debug
      export_summary_for(inductions, headers: INDUCTION_TABLE_HEADERS)
    end

  private

    def target_inductions
      raise NotImplementedError
    end

    def events_for(inductions)
      Event.where(induction_period_id: inductions.pluck(:id)).order(:induction_period_id, :id)
    end

    def event_body_context
      "Automated correction from #{current_appropriate_body.name} to #{new_appropriate_body.name} on #{Date.current}"
    end

    def export_summary_for(records, headers: EVENT_TABLE_HEADERS)
      FileUtils.mkdir_p(csv_file_path)
      tabular_data = []

      CSV.open(csv_file_name, "w", headers:, write_headers: true) do |csv|
        records.map do |record|
          row = headers.map { |attr| fetch_value(record, attr) }
          csv << row
          tabular_data << row
        end
      end

      tabular_data
    end

    def csv_file_path
      Rails.root.join("tmp/transferred_induction_periods/#{self.class::TRANSFER_TYPE}")
    end

    def csv_file_name
      "#{csv_file_path}/#{current_appropriate_body.name} to #{new_appropriate_body.name} on #{cut_off_date}.csv"
    end

    def fetch_value(record, attr)
      attr.split(".").inject(record) { |obj, method| obj&.public_send(method) }
    end
  end
end
