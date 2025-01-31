require 'csv'

module AppropriateBodies::Importers
  class InductionPeriodImporter
    IMPORT_ERROR_LOG = 'tmp/induction_period_import.log'.freeze
    LOGFILE = Rails.root.join("log/induction_period_import.log").freeze

    attr_accessor :csv, :data

    Row = Struct.new(:legacy_appropriate_body_id, :started_on, :finished_on, :induction_programme, :number_of_terms, :trn, :notes, :teacher_id, :appropriate_body_id, keyword_init: true) do
      def range
        started_on...finished_on
      end

      def length
        (finished_on || Time.zone.today) - started_on
      end

      def finished?
        finished_on.present? && number_of_terms.present?
      end

      def ongoing?
        !finished?
      end

      # used in notes
      def to_h
        { appropriate_body_id: legacy_appropriate_body_id, started_on:, finished_on:, induction_programme:, number_of_terms: }
      end

      # used for comparisons in tests
      def to_hash
        { appropriate_body_id:, started_on:, finished_on:, induction_programme: convert_induction_programme, number_of_terms: }
      end

      def to_record
        { appropriate_body_id:, started_on:, finished_on:, induction_programme: convert_induction_programme, number_of_terms:, teacher_id: }
      end

    private

      def convert_induction_programme
        {
          "Full Induction Programme" => "fip",
          "Core Induction Programme" => "cip",
          "School-based Induction Programme" => "diy" # FIXME: check this! - perhaps school-funded fip?
        }.fetch(induction_programme, "fip")
      end
    end

    def initialize(filename, csv: nil)
      @csv = csv || CSV.read(filename, headers: true)

      File.open(IMPORT_ERROR_LOG, 'w') { |f| f.truncate(0) }
      @import_error_log = Logger.new(IMPORT_ERROR_LOG, File::CREAT)
    end

    def rows
      @rows ||= @csv.map { |row| Row.new(**build(row)) }
    end

    def build(row)
      {
        legacy_appropriate_body_id: row['appropriate_body_id'],
        started_on: extract_date(row['started_on']),
        finished_on: extract_date(row['finished_on']),
        induction_programme: row['induction_programme_choice'],
        number_of_terms: row['number_of_terms'].to_i,
        trn: row['trn'],
        notes: [],
        appropriate_body_id: nil,
        teacher_id: nil
      }
    end

    def periods_by_trn
      rows
        .reject { |ip| ip.started_on.nil? }
        .reject { |ip| ip.started_on == Date.new(1, 1, 1) }
        .reject { |ip| ip.finished_on && ip.started_on >= ip.finished_on }
        .group_by(&:trn)
        .select { |_trn, periods| periods.any? { |p| p.finished_on.nil? } }
        .transform_values { |periods| periods.sort_by { |p| [p.started_on, p.length, p.appropriate_body_id] } }
        .each_with_object({}) do |(trn, rows), h|
          keep = []

          rows.each do |current|
            keep << current and next if keep.empty?
            keep << current and next if keep.none? { |already_recorded| current.range.overlap?(already_recorded.range) }

            keep
              .select { |sibling| sibling.range.overlap?(current.range) }
              .each do |sibling|
                original_sibling = sibling.to_h
                original_current = current.to_h

                if sibling.legacy_appropriate_body_id == current.legacy_appropriate_body_id && sibling.induction_programme == current.induction_programme
                  case
                  when current.started_on == sibling.started_on && current.finished? && sibling.ongoing?
                    #               ┌─────────────────────────────────────────┐
                    #   Current     │                  KEEP                   │
                    #               └─────────────────────────────────────────┘
                    #               ┌──────────────────────────────────────────────────────────>
                    #   Sibling     │              DISCARD
                    #               └──────────────────────────────────────────────────────────>
                    current.notes << {
                      heading: "Imported from DQT",
                      body: "DQT held 2 induction periods for this teacher/appropriate body combination with the same start date. The ongoing one was discarded.",
                      data: { originals: [original_sibling, original_current], combined: current.to_h }
                    }
                    keep.delete(sibling)
                    keep << current
                  when current.started_on == sibling.started_on && sibling.finished? && current.ongoing?
                    #               ┌──────────────────────────────────────────────────────────>
                    #   Current     │                  DISCARD
                    #               └──────────────────────────────────────────────────────────>
                    #               ┌─────────────────────────────────────────┐
                    #   Sibling     │              KEEP                       │
                    #               └─────────────────────────────────────────┘
                    sibling.notes << {
                      heading: "Imported from DQT",
                      body: "DQT held 2 induction periods for this teacher/appropriate body combination with the same start date. The ongoing one was discarded.",
                      data: { originals: [original_sibling, original_current], combined: sibling.to_h }
                    }
                    next
                  when sibling.range.cover?(current.range)
                    #                  ┌─────────────────────────────┐
                    #   Current        │           DISCARD           │
                    #                  └─────────────────────────────┘
                    #               ┌──────────────────────────────────────┐
                    #   Sibling     │                KEEP                  │
                    #               └──────────────────────────────────────┘
                    sibling.number_of_terms = [sibling.number_of_terms, current.number_of_terms].max
                    sibling.notes << {
                      heading: "Imported from DQT",
                      body: "DQT held 2 overlapping induction periods for this teacher/appropriate body combination. 1 was discarded",
                      data: { originals: [original_sibling, original_current], combined: sibling.to_h }
                    }
                    next
                  when current.range.cover?(sibling.range)
                    #               ┌──────────────────────────────────────┐
                    #   Current     │               KEEP                   │
                    #               └──────────────────────────────────────┘
                    #                  ┌─────────────────────────────┐
                    #   Sibling        │           DISCARD           │
                    #                  └─────────────────────────────┘
                    current.number_of_terms = [sibling.number_of_terms, current.number_of_terms].max
                    current.notes << {
                      heading: "Imported from DQT",
                      body: "DQT held 2 overlapping induction periods for this teacher/appropriate body combination. 1 was discarded",
                      data: { originals: [original_sibling, original_current], combined: current.to_h }
                    }
                    keep.delete(sibling)
                    keep << current
                  when sibling.range.cover?(current.started_on) && !sibling.range.cover?(current.finished_on)
                    #                     ┌───────────────────────────────────────┐
                    #   Current           │              DISCARD                  │
                    #                     └───────────────────────────────────────┘
                    #                                                           ▼
                    #               ┌─────────────────────────────────────────┬───┐
                    #   Sibling     │                EXTEND                   │╳╳╳│
                    #               └─────────────────────────────────────────┴───┘

                    current.number_of_terms = [sibling.number_of_terms, current.number_of_terms].max
                    sibling.finished_on = current.finished_on
                    sibling.notes << {
                      heading: "Imported from DQT",
                      body: "DQT held 2 overlapping induction periods for this teacher/appropriate body combination. 1 was extended to cover the full duration.",
                      data: { originals: [original_sibling, original_current], combined: sibling.to_h }
                    }
                  when !sibling.range.cover?(current.started_on) && sibling.range.cover(current.finished_on)
                    #               ┌──────────────────────────────────────┐
                    #   Current     │              DISCARD                 │
                    #               └──────────────────────────────────────┘
                    #                  ▼
                    #               ┌─────┬──────────────────────────────────────┐
                    #   Sibling     │╳╳╳╳╳│             EXTEND                   │
                    #               └─────┴──────────────────────────────────────┘
                    sibling.number_of_terms = [sibling.number_of_terms, current.number_of_terms].max
                    sibling.started_on = current.started_on
                    sibling.notes << {
                      heading: "Imported from DQT",
                      body: "DQT held 2 overlapping induction periods for this teacher/appropriate body combination. 1 was extended to cover the full duration.",
                      data: { originals: [original_sibling, original_current], combined: sibling.to_h }
                    }
                  else
                    fail
                  end
                elsif sibling.legacy_appropriate_body_id == current.legacy_appropriate_body_id && sibling.induction_programme != current.induction_programme
                  case
                  when sibling.range.cover?(current.started_on) && !sibling.range.cover?(current.finished_on)
                    #                         ┌─────────────────────────────────┐
                    #   Current               │          KEEP                   │
                    #                         └─────────────────────────────────┘
                    #
                    #               ┌─────────┬┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┐
                    #   Sibling     │ SHRINK  │                    ┊
                    #               └─────────┴┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┘
                    sibling.finished_on = current.started_on
                    sibling.notes << {
                      heading: "Imported from DQT",
                      body: "DQT held 2 overlapping induction periods for this teacher/appropriate body combination with different induction programmes. This record was cut off when the later one started to prevent overlaps.",
                      data: { originals: [original_sibling, original_current] }
                    }
                    keep << current
                  end
                else # different appropriate bodies
                  case
                  when sibling.started_on == current.started_on
                    # TODO: work out what to do here
                  when sibling.range.cover?(current.range) || current.range.cover?(sibling.range)
                    # an induction period from one AB entirely contains one from another,
                    # which do we keep?
                    #
                    # This might never happen in prod so let's ignore it for now
                    # FIXME: log these
                    logger.error("periods contained by other period detected")
                  when sibling.range.cover?(current.started_on) && !sibling.range.cover?(current.finished_on)
                    #                         ┌─────────────────────────────────┐
                    #   Current               │          KEEP                   │
                    #                         └─────────────────────────────────┘
                    #
                    #               ┌─────────┬┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┐
                    #   Sibling     │ SHRINK  │                    ┊
                    #               └─────────┴┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┘
                    sibling.finished_on = current.started_on
                    sibling.notes << {
                      heading: "Imported from DQT",
                      body: "DQT held 2 overlapping induction periods for this teacher with different appropriate bodies. This record was cut off when the later one started to prevent overlaps.",
                      data: { originals: [original_sibling, original_current] }
                    }
                    keep << current
                  end
                end
              end
          end

          h[trn] = keep
        end
    end

    def periods_as_hashes_by_trn
      periods_by_trn.transform_values { |v| v.map(&:to_hash) }
    end

  private

    def logger
      @logger ||= Logger.new(LOGFILE).tap do |l|
        l.level = Logger::Severity::DEBUG
      end
    end

    def extract_date(datetime)
      return if datetime.blank?

      date = datetime.first(10)

      Date.strptime(date, '%m/%d/%Y')
    end
  end
end
