module AppropriateBodies::Importers
  class Importer
    def initialize(appropriate_body_csv:, teachers_csv:, induction_period_csv:, dfe_sign_in_mapping_csv:, dqt_csv:)
      @induction_periods_grouped_by_trn = InductionPeriodImporter.new(induction_period_csv, dqt_csv).periods_by_trn
      @trns_with_induction_periods = @induction_periods_grouped_by_trn.keys
      @teacher_importer_rows = TeacherImporter.new(teachers_csv, @trns_with_induction_periods).rows_with_wanted_statuses
      @active_abs = @induction_periods_grouped_by_trn.flat_map { |_trn, ips| ips.map(&:legacy_appropriate_body_id) }.uniq
      @ab_importer_rows = AppropriateBodyImporter.new(appropriate_body_csv, @active_abs, dfe_sign_in_mapping_csv).rows
    end

    def import!
      ActiveRecord::Base.transaction do
        import_ab_rows
        import_teacher_rows
        import_induction_periods_rows
        import_induction_extensions
        update_event_titles
      end
    end

  private

    def teacher_trn_to_id
      @teacher_trn_to_id ||= Teacher.all.select(:id, :trn).each_with_object({}) do |t, h|
        h[t[:trn]] = t[:id]
      end
    end

    def ab_legacy_id_to_id
      @ab_legacy_id_to_id ||= AppropriateBodyPeriod.all.select(:id, :dqt_id).each_with_object({}) do |ab, h|
        h[ab[:dqt_id]] = ab[:id]
      end
    end

    # Now these will be inactive ABs
    def import_ab_rows
      Rails.logger.info("Active appropriate body periods: #{@active_abs.count}")

      pre_import_count = AppropriateBodyPeriod.count

      @ab_importer_rows.select { |r| r.dqt_id.in?(@active_abs) }.each do |abp|
        AppropriateBodyPeriod.create_with(abp.to_h).find_or_create_by(dqt_id: abp.to_h[:dqt_id])
      end

      post_import_count = AppropriateBodyPeriod.count
      import_count = post_import_count - pre_import_count

      Rails.logger.info("Appropriate body periods inserted: #{import_count}")
    end

    def import_teacher_rows
      Rails.logger.info("Inactive Teachers: #{@teacher_importer_rows.count}")

      pre_import_count = Teacher.count

      Teacher.insert_all!(@teacher_importer_rows.map(&:to_h))

      post_import_count = Teacher.count
      import_count = post_import_count - pre_import_count

      Rails.logger.info("Teachers inserted: #{import_count}")
    end

    def import_induction_periods_rows
      induction_period_rows = []

      @induction_periods_grouped_by_trn.slice(*teacher_trn_to_id.keys).each do |trn, induction_periods|
        induction_periods.each do |ip|
          begin
            ip.teacher_id = teacher_trn_to_id.fetch(trn)
          rescue KeyError
            Rails.logger.error("No teacher found with trn: #{trn}")
            next
          end

          begin
            ip.appropriate_body_period_id = ab_legacy_id_to_id.fetch(ip.legacy_appropriate_body_id)
          rescue KeyError
            Rails.logger.error("No appropriate body period found with dqt_id: #{ip.legacy_appropriate_body_id}")
            next
          end

          induction_period_rows << ip
        end
      end

      pre_import_count = InductionPeriod.count
      induction_period_ids = InductionPeriod.insert_all!(induction_period_rows.map(&:to_record), returning: [:id])
      post_import_count = InductionPeriod.count
      import_count = post_import_count - pre_import_count

      Rails.logger.info("Induction periods inserted: #{import_count}")

      events = induction_period_rows
          .each_with_index { |row, i| row.id = induction_period_ids[i]["id"] }
          .flat_map(&:events).flatten

      pre_import_count = Event.count

      Event.insert_all(events)

      post_import_count = Event.count
      import_count = post_import_count - pre_import_count

      Rails.logger.info("Events inserted: #{import_count}")
    end

    def import_induction_extensions
      induction_extensions = @teacher_importer_rows.select { |tir| tir.extension_terms.present? }.map do |row|
        {
          teacher_id: teacher_trn_to_id.fetch(row.trn),
          number_of_terms: row.extension_terms
        }
      end

      pre_import_count = InductionExtension.count

      InductionExtension.insert_all!(induction_extensions)

      post_import_count = InductionExtension.count
      import_count = post_import_count - pre_import_count

      Rails.logger.info("Induction extensions inserted: #{import_count}")
    end

    def update_event_titles
      statements = [<<~CLAIM, <<~RELEASE]
        update events e
        set heading = t.trs_first_name || ' ' || t.trs_last_name || ' was claimed by ' || ab.name
        from teachers t, appropriate_body_periods ab
        where e.heading = 'placeholder'
        and e.event_type = 'induction_period_opened'
        and e.teacher_id = t.id
        and e.appropriate_body_period_id = ab.id;
      CLAIM
        update events e
        set heading = t.trs_first_name || ' ' || t.trs_last_name || ' was released by ' || ab.name
        from teachers t, appropriate_body_periods ab
        where e.heading = 'placeholder'
        and e.event_type = 'induction_period_closed'
        and e.teacher_id = t.id
        and e.appropriate_body_period_id = ab.id;
      RELEASE

      ActiveRecord::Base.connection.execute(statements.join(";"))
    end
  end
end
