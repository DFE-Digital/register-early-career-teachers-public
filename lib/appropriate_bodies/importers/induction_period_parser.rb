require "csv"

module AppropriateBodies::Importers
  class InductionPeriodParser
    PARSER_ERROR_LOG = "log/dqt_induction_period_parser.log"

    # 2 legacy teachers with inductions have already been imported manually
    UNWANTED_TEACHER_IDS = [76_075, 93_314].freeze
    # Import cut off date
    CUTOFF_DATE = Date.new(2024, 8, 31).freeze

    InductionEvent = Struct.new(
      :appropriate_body_period_id,
      :induction_period_id,
      :teacher_id,
      :happened_at,
      :metadata,
      keyword_init: true
    ) do
      def self.event_type
        raise NotImplementedError, "Subclasses must define event_type"
      end

      def to_h
        {
          author_type: "system",
          heading: "placeholder",
          event_type: self.class.event_type,
          body: "Imported from DQT",
          appropriate_body_period_id:,
          induction_period_id:,
          teacher_id:,
          metadata:,
          happened_at:,
        }
      end
    end

    class ClaimEvent < InductionEvent
      def self.event_type = "induction_period_opened"
    end

    class ReleaseEvent < InductionEvent
      def self.event_type = "induction_period_closed"
    end

    class PassEvent < InductionEvent
      def self.event_type = "teacher_passes_induction"
    end

    class FailEvent < InductionEvent
      def self.event_type = "teacher_fails_induction"
    end

    ImportEvent = Struct.new(:appropriate_body_period_id, :induction_period_id, :teacher_id, :metadata, :heading, :body, keyword_init: true) do
      def to_h
        {
          appropriate_body_period_id:,
          author_type: "system",
          body:,
          event_type: "import_from_dqt",
          happened_at: Time.zone.now,
          heading:,
          induction_period_id:,
          metadata:,
          teacher_id:,
        }
      end
    end

    Row = Struct.new(:legacy_appropriate_body_id, :started_on, :finished_on, :induction_programme, :number_of_terms, :trn, :notes, :teacher_id, :appropriate_body_period_id, :id, :induction_status, keyword_init: true) do
      # @return [Integer] days
      def length
        (finished_on - started_on).to_i
      end

      def range
        started_on...finished_on
      end

      # @return [Boolean]
      def finished?
        finished_on.present? && number_of_terms.present?
      end

      # @return [Boolean]
      def ongoing?
        !finished?
      end

      # used in notes
      def to_h
        {
          legacy_appropriate_body_id:, # DQT UUID
          started_on:,
          finished_on:,
          induction_programme:,
          number_of_terms:
        }
      end

      # Inserted into database
      def to_record
        {
          teacher_id:,
          appropriate_body_period_id:,
          started_on:,
          finished_on: fixed_finished_on,
          induction_programme: convert_induction_programme,
          number_of_terms: fixed_number_of_terms,
          outcome:
        }
      end

      # @return [Array<Hash>] each IP has a single claim and a single result event
      def events
        [
          claim_event,
          result_event,
          *notes.map { |note| note_event(**note) }
        ].compact.map(&:to_h)
      end

    private

      # @return [Symbol, nil]
      def outcome
        return :pass if passed?

        :fail if failed?
      end

      # @return [Boolean]
      def released?
        finished? && induction_status.blank?
      end

      # @return [Boolean]
      def passed?
        finished? && induction_status.to_s.eql?("Passed")
      end

      # @return [Boolean]
      def failed?
        finished? && induction_status.to_s.starts_with?("Failed")
      end

      # @return [Float, nil]
      def fixed_number_of_terms
        return if finished_on.blank?

        number_of_terms.clamp(0.0, 16.0).round(1)
      end

      # @return [Date, nil]
      def fixed_finished_on
        finished_on == started_on ? finished_on + 1 : finished_on
      end

      # @return [String]
      def convert_induction_programme
        return "pre_september_2021" if started_on < ::ECF_ROLLOUT_DATE

        {
          "Full Induction Programme" => "fip",
          "Core Induction Programme" => "cip",
          "School-based Induction Programme" => "diy"
        }.fetch(induction_programme, "unknown")
      end

      # @return [Hash]
      def common_event_values
        { teacher_id:, appropriate_body_period_id:, induction_period_id: id }
      end

      # @return [ClaimEvent]
      def claim_event
        ClaimEvent.new(happened_at: started_on, **common_event_values)
      end

      # @return [ReleaseEvent, PassEvent, FailEvent, nil]
      def result_event
        case
        when released? then ReleaseEvent.new(happened_at: finished_on, **common_event_values)
        when passed? then PassEvent.new(happened_at: finished_on, **common_event_values)
        when failed? then FailEvent.new(happened_at: finished_on, **common_event_values)
        end
      end

      # @return [ImportEvent]
      def note_event(data:, heading:, body:)
        ImportEvent.new(**common_event_values, metadata: data, heading:, body:)
      end
    end

    attr_accessor :csv,
                  :data_csv,
                  :logger,
                  :offshore_dqt_uuids,
                  :all_dqt_uuids,
                  :trns_already_persisted_with_inductions

    def initialize(data_csv:, logger: nil)
      @data_csv = data_csv
      @offshore_dqt_uuids = OFFSHORE_DQT_UUIDS.to_set
      @all_dqt_uuids = AppropriateBodyPeriod.pluck(:dqt_id).to_set
      @trns_already_persisted_with_inductions = Teacher.where(id: UNWANTED_TEACHER_IDS).pluck(:trn).to_set

      File.open(PARSER_ERROR_LOG, "w") { |f| f.truncate(0) }
      @logger = logger || Logger.new(PARSER_ERROR_LOG, File::CREAT)
    end

    # @return [Array<Struct>] all rows
    def rows
      @rows ||= csv_rows.map { |row| Row.new(**build(row)) }
    end

    # Returns ANY importable finished rows, even finished rows from someone who had ongoing one from the first import
    #
    # 1. reject rows with gaps
    # 2. reject rows with invalid dates
    # 3. reject rows associated to ABs we are removing
    # 4. reject rows for select teachers already imported
    #
    # @return [Hash{String => Array<Struct>}] filtered rows
    def periods_by_trn
      rows
        .reject { |row|
          if row.trn.nil? || row.legacy_appropriate_body_id.nil?
            log_error("cannot be imported because TRN or AB is missing",
                      trn: row.trn,
                      dqt_id: row.legacy_appropriate_body_id)
          else
            false
          end
        }
        .reject { |row|
          if row.started_on.nil?
            log_error("cannot be imported because started_on is nil",
                      trn: row.trn,
                      dqt_id: row.legacy_appropriate_body_id)
          else
            false
          end
        }
        .reject { |row|
          if row.finished_on.nil?
            log_error("cannot be imported because finished_on is nil",
                      trn: row.trn,
                      dqt_id: row.legacy_appropriate_body_id)
          else
            false
          end
        }
        .reject { |row|
          if row.started_on == Date.new(1, 1, 1)
            log_error("cannot be imported because started_on is 0001-01-01",
                      trn: row.trn,
                      dqt_id: row.legacy_appropriate_body_id)
          else
            false
          end
        }
        .reject { |row|
          if row.finished_on && row.started_on > row.finished_on
            log_error("cannot be imported because started_on is greater than finished_on",
                      trn: row.trn,
                      dqt_id: row.legacy_appropriate_body_id)
          else
            false
          end
        }
        .reject { |row|
          if row.legacy_appropriate_body_id.in?(offshore_dqt_uuids)
            log_error("cannot be imported because AB is offshore",
                      trn: row.trn,
                      dqt_id: row.legacy_appropriate_body_id)
          else
            false
          end
        }
        .reject { |row|
          if row.trn.in?(trns_already_persisted_with_inductions)
            log_error("cannot be imported because teacher already exists with inductions",
                      trn: row.trn,
                      dqt_id: row.legacy_appropriate_body_id)
          else
            false
          end
        }
        .sort_by(&:trn)
        .group_by(&:trn)
        .transform_values { |periods|
          periods.sort_by { |p| [p.started_on, p.length, p.appropriate_body_period_id] }
        }
        .each_with_object({}) do |(trn, periods), hashmap|
          keep = []
          heading = "Amended while importing from DQT"

          periods.each do |current|
            # advance start date if it predates policy inception
            if current.started_on < ::STATUTORY_INDUCTION_ROLLOUT_DATE
              current.notes << {
                heading:,
                body: "Induction period curtailed because it started before the statutory rollout",
                data: { originals: [current.dup] }
              }

              current.started_on = ::STATUTORY_INDUCTION_ROLLOUT_DATE

              keep << current
              next
            end

            # retard end date (add if missing) if it postdates the initial import
            if current.legacy_appropriate_body_id.in?(all_dqt_uuids) && current.finished_on > CUTOFF_DATE
              current.notes << {
                heading:,
                body: "Induction period curtailed because it finished after appropriate body status lost",
                data: { originals: [current.dup] }
              }

              current.finished_on = current.started_on >= CUTOFF_DATE ? current.started_on + 1 : CUTOFF_DATE

              keep << current
              next
            end

            if keep.empty?
              keep << current
              next
            end

            if keep.none? { |already_recorded| current.range.overlap?(already_recorded.range) }
              keep << current
              next
            end

            keep
              .select { |sibling| sibling.range.overlap?(current.range) }
              .each do |sibling|
                original_sibling = sibling.to_h
                original_current = current.to_h

                # same appropriate body and matching programme type
                if sibling.legacy_appropriate_body_id == current.legacy_appropriate_body_id &&
                    sibling.induction_programme == current.induction_programme

                  case
                  when sibling.range.cover?(current.range)
                    #                  ┌─────────────────────────────┐
                    #   CURRENT        │           DISCARD           │
                    #                  └─────────────────────────────┘
                    #               ┌──────────────────────────────────────┐
                    #   SIBLING     │                KEEP                  │
                    #               └──────────────────────────────────────┘
                    sibling.number_of_terms = [sibling.number_of_terms, current.number_of_terms].max
                    sibling.notes << {
                      heading:,
                      body: "DQT held 2 overlapping induction periods for this teacher/appropriate body combination. 1 was discarded",
                      data: { originals: [original_sibling, original_current], combined: sibling.to_h }
                    }
                    next

                  when current.range.cover?(sibling.range)
                    #               ┌──────────────────────────────────────┐
                    #   CURRENT     │               KEEP                   │
                    #               └──────────────────────────────────────┘
                    #                  ┌─────────────────────────────┐
                    #   SIBLING        │           DISCARD           │
                    #                  └─────────────────────────────┘
                    current.number_of_terms = [sibling.number_of_terms, current.number_of_terms].max
                    current.notes << {
                      heading:,
                      body: "DQT held 2 overlapping induction periods for this teacher/appropriate body combination. 1 was discarded",
                      data: { originals: [original_sibling, original_current], combined: current.to_h }
                    }
                    keep.delete(sibling)
                    keep << current

                  when sibling.range.cover?(current.started_on) && !sibling.range.cover?(current.finished_on)
                    #                     ┌───────────────────────────────────────┐
                    #   CURRENT           │              DISCARD                  │
                    #                     └───────────────────────────────────────┘
                    #                                                           ▼
                    #               ┌─────────────────────────────────────────┬───┐
                    #   SIBLING     │                EXTEND                   │+ +│
                    #               └─────────────────────────────────────────┴───┘
                    current.number_of_terms = [sibling.number_of_terms, current.number_of_terms].max
                    sibling.finished_on = current.finished_on
                    sibling.notes << {
                      heading:,
                      body: "DQT held 2 overlapping induction periods for this teacher/appropriate body combination. 1 was extended to cover the full duration.",
                      data: { originals: [original_sibling, original_current], combined: sibling.to_h }
                    }

                  when !sibling.range.cover?(current.started_on) && sibling.range.cover(current.finished_on)
                    #               ┌──────────────────────────────────────┐
                    #   CURRENT     │              DISCARD                 │
                    #               └──────────────────────────────────────┘
                    #                  ▼
                    #               ┌─────┬──────────────────────────────────────┐
                    #   SIBLING     │+ + +│             EXTEND                   │
                    #               └─────┴──────────────────────────────────────┘
                    sibling.number_of_terms = [sibling.number_of_terms, current.number_of_terms].max
                    sibling.started_on = current.started_on
                    sibling.notes << {
                      heading:,
                      body: "DQT held 2 overlapping induction periods for this teacher/appropriate body combination. 1 was extended to cover the full duration.",
                      data: { originals: [original_sibling, original_current], combined: sibling.to_h }
                    }

                  else
                    fail
                  end

                # same appropriate body and conflicting programme type
                elsif sibling.legacy_appropriate_body_id == current.legacy_appropriate_body_id &&
                    sibling.induction_programme != current.induction_programme

                  case
                  when sibling.range.cover?(current.started_on) && !sibling.range.cover?(current.finished_on)
                    #                         ┌─────────────────────────────────┐
                    #   CURRENT               │          KEEP                   │
                    #                         └─────────────────────────────────┘
                    #
                    #               ┌─────────┬┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┐
                    #   SIBLING     │ SHRINK  │ - - - - - - - - - -┊
                    #               └─────────┴┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┘
                    sibling.finished_on = current.started_on
                    sibling.notes << {
                      heading:,
                      body: "DQT held 2 overlapping induction periods for this teacher/appropriate body combination with different induction programmes. This record was cut off when the later one started to prevent overlaps.",
                      data: { originals: [original_sibling, original_current] }
                    }
                    keep << current
                  end

                # different appropriate body
                else

                  case
                  when sibling.started_on == current.started_on
                    keep.delete(sibling)
                    log_error(
                      "two induction periods with different appropriate bodies that start on the same day found",
                      trn: current.trn,
                      dqt_id: [current.legacy_appropriate_body_id, sibling.legacy_appropriate_body_id]
                    )

                  when sibling.range.cover?(current.range) || current.range.cover?(sibling.range)
                    keep.delete(sibling)
                    log_error(
                      "two induction periods with different appropriate bodies where one contains the other",
                      trn: current.trn,
                      dqt_id: [current.legacy_appropriate_body_id, sibling.legacy_appropriate_body_id]
                    )

                  when sibling.range.cover?(current.started_on) && !sibling.range.cover?(current.finished_on)
                    #                         ┌─────────────────────────────────┐
                    #   CURRENT               │          KEEP                   │
                    #                         └─────────────────────────────────┘
                    #
                    #               ┌─────────┬┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┐
                    #   SIBLING     │ SHRINK  │ - - - - - - - - - -┊
                    #               └─────────┴┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┘
                    sibling.finished_on = current.started_on
                    sibling.notes << {
                      heading:,
                      body: "DQT held 2 overlapping induction periods for this teacher with different appropriate bodies. This record was cut off when the later one started to prevent overlaps.",
                      data: { originals: [original_sibling, original_current] }
                    }
                    keep << current
                  end

                end
              end
          end

          keep = keep.reject { |edited_period| edited_period.length <= 1 }

          next if keep.empty?

          hashmap[trn] = keep
        end
    end

  private

    # @param row [CSV::Row]
    # @return [Hash]
    def build(row)
      {
        legacy_appropriate_body_id: row["appropriate_body_id"]&.downcase,
        started_on: extract_date(row["started_on"]),
        finished_on: extract_date(row["finished_on"]),
        induction_programme: row["induction_programme_choice"],
        number_of_terms: row["number_of_terms"].to_f,
        trn: row["trn"],
        notes: [],
        appropriate_body_period_id: nil,
        teacher_id: nil,
        induction_status: nil,
      }
    end

    # @return [CSV::Table]
    def csv_rows
      genuine_data? ? CSV.read(data_csv, headers: true) : CSV.parse(data_csv, headers: true)
    end

    # @return [Boolean]
    def genuine_data?
      data_csv.to_s.ends_with?("inductionperiods.csv")
    end

    # @param message [String]
    # @param trn [String]
    # @param dqt_id [String, Array<String>]
    # @return [void]
    def log_error(message, trn:, dqt_id:)
      uuids = Array(dqt_id).join(", ")
      logger.error("#{message} trn: #{trn} dqt_id: #{uuids}")
    end

    # @param datetime [String]
    # @return [Date, nil]
    def extract_date(datetime)
      return if datetime.blank?

      date = datetime.first(10)
      Date.strptime(date, "%m/%d/%Y")
    end
  end
end
