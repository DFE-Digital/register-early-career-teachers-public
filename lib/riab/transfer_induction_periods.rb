# Utility base class to select and amend inductions associated to the wrong appropriate body
#
require "table_print"

module RIAB
  class TransferInductionPeriods
    # @return [Array<String>]
    INDUCTION_TABLE_HEADERS = %w[
      id
      started_on
      finished_on
      appropriate_body_id
      teacher_id
    ].freeze

    # @return [Array<String>]
    EVENT_TABLE_HEADERS = %w[
      id
      induction_period.id
      induction_period.started_on
      induction_period.finished_on
      appropriate_body.id
      appropriate_body.name
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

    # @param from [AppropriateBody] current owner
    # @param to [AppropriateBody] new owner
    # @param on [Date] when the change of ownership occurred
    def initialize(from:, to:, on:)
      @current_appropriate_body = from
      @new_appropriate_body = to
      @cut_off_date = on
      @inductions = target_inductions
    end

    def debug
      configure_table_print(:screen)

      export_summary_for(inductions, headers: INDUCTION_TABLE_HEADERS)
    end

  private

    def target_inductions
      raise NotImplementedError
    end

    def events_for(inductions)
      Event.where(induction_period_id: inductions.pluck(:id)).order(:induction_period_id, :id)
    end

    # @return [TablePrint::Returnable]
    def export_summary_for(rows, headers: EVENT_TABLE_HEADERS)
      tp rows, *headers
    end

    # Console and exported changes
    def configure_table_print(format)
      tp.set :capitalize_headers, false
      case format
      when :screen
        tp.clear :max_width
        tp.clear :separator
        tp.clear :io
      when :csv
        tp.set :max_width, 100
        tp.set :separator, ","
        tp.set :io, File.open(Rails.root.join("tmp/#{csv_file_name}"), "w")
      end
    end

    def csv_file_name
      "#{self.class.name} from #{current_appropriate_body.name} to #{new_appropriate_body.name} on #{cut_off_date}.csv"
    end
  end
end
