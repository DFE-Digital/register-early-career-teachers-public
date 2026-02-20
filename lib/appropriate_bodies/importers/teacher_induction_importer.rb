module AppropriateBodies::Importers
  # Offshore ABs to exclude from import
  OFFSHORE_DQT_UUIDS = [
    "7cdd3e82-c1ae-e311-b8ed-005056822391", # Isle of Man Offshore Establishments
    "82dd3e82-c1ae-e311-b8ed-005056822391", # Guernsey Offshore Establishments
    "86dd3e82-c1ae-e311-b8ed-005056822391", # Jersey Offshore Establishments
    "8add3e82-c1ae-e311-b8ed-005056822391", # Gibraltar Overseas Establishments
    "74c83b8a-b0c4-e311-8a4f-005056822390", # Ministry of Defence (MoD) Schools
  ].freeze

  # This class imports teachers and their induction periods from DQT export CSVs.
  # It also creates events for the start and end of each induction period, and any extensions.
  class TeacherInductionImporter
    BATCH_SIZE = 1_000

    IMPORT_INFO_LOG = "log/dqt_import_info.log"

    # Bulk replace placeholder event headings
    STATEMENTS = [<<~CLAIMED, <<~RELEASED, <<~PASSED, <<~FAILED].freeze
      update events e
      set heading = t.trs_first_name || ' ' || t.trs_last_name || ' was claimed by ' || ab.name
      from teachers t, appropriate_body_periods ab
      where e.heading = 'placeholder'
      and e.event_type = 'induction_period_opened'
      and e.teacher_id = t.id
      and e.appropriate_body_period_id = ab.id;
    CLAIMED
      update events e
      set heading = t.trs_first_name || ' ' || t.trs_last_name || ' was released by ' || ab.name
      from teachers t, appropriate_body_periods ab
      where e.heading = 'placeholder'
      and e.event_type = 'induction_period_closed'
      and e.teacher_id = t.id
      and e.appropriate_body_period_id = ab.id;
    RELEASED
      update events e
      set heading = t.trs_first_name || ' ' || t.trs_last_name || ' passed induction'
      from teachers t, appropriate_body_periods ab
      where e.heading = 'placeholder'
      and e.event_type = 'teacher_passes_induction'
      and e.teacher_id = t.id
      and e.appropriate_body_period_id = ab.id;
    PASSED
      update events e
      set heading = t.trs_first_name || ' ' || t.trs_last_name || ' failed induction'
      from teachers t, appropriate_body_periods ab
      where e.heading = 'placeholder'
      and e.event_type = 'teacher_fails_induction'
      and e.teacher_id = t.id
      and e.appropriate_body_period_id = ab.id;
    FAILED

    attr_reader :teachers_with_inductions,
                :teachers,
                :logger

    def initialize(teachers_csv:, induction_period_csv:, logger: nil)
      @teachers_with_inductions =
        InductionPeriodParser.new(data_csv: induction_period_csv)
        .periods_by_trn
        .select { |_trn, induction_periods| induction_periods.present? }

      @teachers =
        TeacherParser.new(
          data_csv: teachers_csv,
          trns_with_induction_periods: @teachers_with_inductions.keys
        )

      File.open(IMPORT_INFO_LOG, "w") { |f| f.truncate(0) }
      @logger = logger || Logger.new(IMPORT_INFO_LOG, File::CREAT)
    end

    def import!
      ActiveRecord::Base.transaction do
        logger.info "import running"

        import_teacher_rows
        import_induction_periods_rows
        import_induction_extensions
        update_event_titles

        logger.info "import completed"
      end
    end

  private

    # @return [Hash{String => Integer}]
    def teacher_trn_to_id
      @teacher_trn_to_id ||=
        Teacher.all.pluck(:trn, :id).each_with_object({}) do |(trn, id), hashmap|
          hashmap[trn] = id
        end
    end

    # @return [Hash{String => String}]
    def teacher_trn_to_status
      @teacher_trn_to_status ||=
        Teacher.all.pluck(:trn, :trs_induction_status).each_with_object({}) do |(trn, status), hashmap|
          hashmap[trn] = status
        end
    end

    # @return [Hash{String => Integer}]
    def ab_legacy_uuid_to_id
      @ab_legacy_uuid_to_id ||=
        AppropriateBodyPeriod.all.pluck(:dqt_id, :id).each_with_object({}) do |(dqt_id, id), hashmap|
          hashmap[dqt_id] = id
        end
    end

    def import_teacher_rows
      ActiveRecord::Base.transaction do
        teachers.rows.map(&:to_h).each_slice(BATCH_SIZE).map do |batch|
          teacher_result = Teacher.insert_all!(batch)
          logger.info("Teachers inserted: #{teacher_result.count}")
        end
      end
    end

    def import_induction_periods_rows
      induction_period_rows = []

      teachers_with_inductions.slice(*teacher_trn_to_id.keys).each do |trn, induction_periods|
        induction_periods.each do |ip|
          begin
            ip.teacher_id = teacher_trn_to_id.fetch(trn)
          rescue KeyError
            logger.info("No teacher found with trn: #{trn}")
            next
          end

          begin
            ip.appropriate_body_period_id = ab_legacy_uuid_to_id.fetch(ip.legacy_appropriate_body_id)
          rescue KeyError
            logger.info("No appropriate body period found with dqt_id: #{ip.legacy_appropriate_body_id}")
            next
          end

          # The final induction needs the outcome
          begin
            if induction_periods.select(&:finished_on).max_by(&:finished_on).eql?(ip)
              ip.induction_status = teacher_trn_to_status.fetch(trn)
            end
          rescue KeyError
            logger.info("Unable to set status '#{teacher_trn_to_status.fetch(trn)}' for trn: #{trn}")
            next
          end

          induction_period_rows << ip
        end
      end

      ActiveRecord::Base.transaction do
        induction_period_rows.each_slice(BATCH_SIZE).map do |batch|
          induction_period_data = batch.map(&:to_record)
          induction_period_result = InductionPeriod.insert_all!(induction_period_data, returning: [:id])

          logger.info("Induction periods inserted: #{induction_period_result.count}")

          event_data = batch
                        .each_with_index { |row, i| row.id = induction_period_result[i]["id"] }
                        .flat_map(&:events).flatten

          event_result = Event.insert_all!(event_data)

          logger.info("Events inserted: #{event_result.count}")
        end
      end
    end

    def import_induction_extensions
      data = teachers.rows.select { |tir| tir.extension_terms.present? }.map do |row|
        {
          teacher_id: teacher_trn_to_id.fetch(row.trn),
          number_of_terms: row.extension_terms
        }
      end

      extension_result = InductionExtension.insert_all!(data)
      logger.info("Induction extensions inserted: #{extension_result.count}")
    end

    def update_event_titles
      debugger
      ActiveRecord::Base.connection.execute(STATEMENTS.join(";"))
      logger.info "Event heading placeholders replaced"
    end
  end
end
