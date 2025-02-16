require 'csv'

module AppropriateBodies::Importers
  class InductionPeriodImporter
    IMPORT_ERROR_LOG = 'log/induction_period_error.log'.freeze
    ECF_CUTOFF = Date.new(2021, 9, 1).freeze

    attr_accessor :csv, :data

    ClaimEvent = Struct.new(:appropriate_body_id, :induction_period_id, :teacher_id, :happened_at, :metadata, keyword_init: true) do
      def event_type = :appropriate_body_claims_teacher

      def to_h
        {
          appropriate_body_id:,
          author_type: 'system',
          body: nil,
          event_type:,
          happened_at:,
          heading: 'placeholder',
          induction_period_id:,
          metadata:,
          teacher_id:,
        }
      end
    end

    ReleaseEvent = Struct.new(:appropriate_body_id, :induction_period_id, :teacher_id, :happened_at, :metadata, keyword_init: true) do
      def event_type = :appropriate_body_releases_teacher

      def to_h
        {
          appropriate_body_id:,
          author_type: 'system',
          body: nil,
          event_type:,
          happened_at:,
          heading: 'placeholder',
          induction_period_id:,
          metadata:,
          teacher_id:,
        }
      end
    end

    ImportEvent = Struct.new(:appropriate_body_id, :induction_period_id, :teacher_id, :metadata, :heading, :body, keyword_init: true) do
      def event_type = :import_from_dqt

      def to_h
        {
          appropriate_body_id:,
          author_type: 'system',
          body:,
          event_type:,
          happened_at: Time.zone.now,
          heading:,
          induction_period_id:,
          metadata:,
          teacher_id:,
        }
      end
    end

    Row = Struct.new(:legacy_appropriate_body_id, :started_on, :finished_on, :induction_programme, :number_of_terms, :trn, :notes, :teacher_id, :appropriate_body_id, :id, keyword_init: true) do
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
        { legacy_appropriate_body_id:, started_on:, finished_on:, induction_programme:, number_of_terms: }
      end

      # used for comparisons in tests
      def to_hash
        { appropriate_body_id:, started_on:, finished_on: fixed_finished_on, induction_programme: convert_induction_programme, number_of_terms: fixed_number_of_terms }
      end

      def to_record
        { teacher_id:, appropriate_body_id:, started_on:, finished_on: fixed_finished_on, induction_programme: convert_induction_programme, number_of_terms: fixed_number_of_terms }
      end

      def events
        common_values = { teacher_id:, appropriate_body_id:, induction_period_id: id }

        import_events = notes.map { |n| ImportEvent.new(**common_values, metadata: n[:data], heading: n[:heading], body: n[:body]) }

        [
          ClaimEvent.new(happened_at: started_on, **common_values),
          (ReleaseEvent.new(happened_at: finished_on, **common_values) if finished_on.present?),
          *import_events
        ].compact.map(&:to_h)
      end

    private

      def fixed_number_of_terms
        (finished_on.present?) ? number_of_terms : nil
      end

      def fixed_finished_on
        finished_on == started_on ? finished_on + 1 : finished_on
      end

      def convert_induction_programme
        return "pre_september_2021" if started_on < ECF_CUTOFF

        {
          "Full Induction Programme" => "fip",
          "Core Induction Programme" => "cip",
          "School-based Induction Programme" => "diy"
        }.fetch(induction_programme, "unknown")
      end
    end

    def initialize(filename, cutoff_csv_filename, csv: nil, cutoff_csv: nil)
      @csv = csv || CSV.read(filename, headers: true)
      @cutoff_csv = cutoff_csv || CSV.read(cutoff_csv_filename, headers: true)

      File.open(IMPORT_ERROR_LOG, 'w') { |f| f.truncate(0) }
    end

    def rows
      @rows ||= @csv.map { |row| Row.new(**build(row)) }
    end

    def old_abs
      @old_abs ||= @cutoff_csv.map { |r| r['dqt_id'].downcase }
    end

    def build(row)
      {
        legacy_appropriate_body_id: row['appropriate_body_id']&.downcase,
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
        .reject { |ip|
          if ip.started_on.nil?
            log_error("cannot be imported because started_on is nil", trn: ip.trn, legacy_appropriate_body_id: ip.legacy_appropriate_body_id)
          else
            false
          end
        }
        .reject { |ip|
          if ip.started_on == Date.new(1, 1, 1)
            log_error("cannot be imported because started_on is 0001-01-01", trn: ip.trn, legacy_appropriate_body_id: ip.legacy_appropriate_body_id)
          else
            false
          end
        }
        .reject { |ip|
          if ip.finished_on && ip.started_on > ip.finished_on
            log_error("cannot be imported because started_on is greater than finished_on", trn: ip.trn, legacy_appropriate_body_id: ip.legacy_appropriate_body_id)
          else
            false
          end
        }
        .group_by(&:trn)
        .transform_values { |periods| periods.sort_by { |p| [p.started_on, p.length, p.appropriate_body_id] } }
        .each_with_object({}) do |(trn, rows), h|
          keep = []

          cutoff_date = Date.new(2024, 8, 31)

          rows.each do |current|
            if current.legacy_appropriate_body_id.in?(old_abs) && (current.finished_on.nil? || current.finished_on > cutoff_date)
              current.notes << {
                heading: "Amended while importing from DQT",
                body: "Induction period curtailed because it finished after appropriate body status lost",
                data: { originals: [current.dup] }
              }

              current.finished_on = if current.started_on >= cutoff_date
                                      # NOTE: this only affects one record
                                      current.started_on + 1
                                    else
                                      cutoff_date
                                    end

              keep << current
              next
            end

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
                      heading: "Amended while importing from DQT",
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
                      heading: "Amended while importing from DQT",
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
                      heading: "Amended while importing from DQT",
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
                      heading: "Amended while importing from DQT",
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
                      heading: "Amended while importing from DQT",
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
                      heading: "Amended while importing from DQT",
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
                      heading: "Amended while importing from DQT",
                      body: "DQT held 2 overlapping induction periods for this teacher/appropriate body combination with different induction programmes. This record was cut off when the later one started to prevent overlaps.",
                      data: { originals: [original_sibling, original_current] }
                    }
                    keep << current
                  end
                else # different appropriate bodies
                  case
                  when sibling.started_on == current.started_on
                    keep.delete(sibling)
                    log_error(
                      "two induction periods with different appropriate bodies that start on the same day found",
                      trn: current.trn,
                      legacy_appropriate_body_id: [current.legacy_appropriate_body_id, sibling.legacy_appropriate_body_id]
                    )
                  when sibling.range.cover?(current.range) || current.range.cover?(sibling.range)
                    # an induction period from one AB entirely contains one from another,
                    # which do we keep?
                    #
                    # This might never happen in prod so let's ignore it for now
                    keep.delete(sibling)
                    log_error(
                      "two induction periods with different appropriate bodies where one contains the other",
                      trn: current.trn,
                      legacy_appropriate_body_id: [current.legacy_appropriate_body_id, sibling.legacy_appropriate_body_id]
                    )
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
                      heading: "Amended while importing from DQT",
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

    def logger
      @logger ||= Logger.new(IMPORT_ERROR_LOG, File::CREAT)
    end

  private

    def log_error(message, trn:, legacy_appropriate_body_id:)
      logger.error(
        [
          message,
          ("trn: #{trn}" if trn),
          ("appropriate_body_id: #{legacy_appropriate_body_id}" if legacy_appropriate_body_id)
        ].compact.join(" ")
      )
    end

    def extract_date(datetime)
      return if datetime.blank?

      date = datetime.first(10)

      Date.strptime(date, '%m/%d/%Y')
    end
  end
end
