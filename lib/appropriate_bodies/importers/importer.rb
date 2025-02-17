module AppropriateBodies::Importers
  class Importer
    def initialize(appropriate_body_csv:, teachers_csv:, induction_period_csv:, dfe_sign_in_mapping_csv:, admin_csv:, cutoff_csv:)
      @induction_periods_grouped_by_trn = InductionPeriodImporter.new(induction_period_csv, cutoff_csv).periods_by_trn

      @active_teachers = @induction_periods_grouped_by_trn.keys
      @teacher_importer_rows = TeacherImporter.new(teachers_csv, @active_teachers).rows

      @active_abs = @induction_periods_grouped_by_trn.flat_map { |_trn, ips| ips.map(&:legacy_appropriate_body_id) }.uniq
      @ab_importer_rows = AppropriateBodyImporter.new(appropriate_body_csv, @active_abs, dfe_sign_in_mapping_csv).rows

      @admin_csv = CSV.read(admin_csv, headers: true)
    end

    def import!
      import_ab_rows
      import_teacher_rows
      import_induction_periods_rows
      import_induction_extensions

      update_event_titles
      insert_admins
    end

  private

    def teacher_trn_to_id
      @teacher_trn_to_id ||= Teacher.all.select(:id, :trn).each_with_object({}) do |t, h|
        h[t[:trn]] = t[:id]
      end
    end

    def ab_legacy_id_to_id
      @ab_legacy_id_to_id ||= AppropriateBody.all.select(:id, :legacy_id).each_with_object({}) do |ab, h|
        h[ab[:legacy_id]] = ab[:id]
      end
    end

    def import_ab_rows
      Rails.logger.info("Active appropriate bodies: #{@active_abs.count}")
      AppropriateBody.insert_all!(@ab_importer_rows.select { |r| r.legacy_id.in?(@active_abs) }.map(&:to_h))
      Rails.logger.info("Appropriate bodies inserted: #{AppropriateBody.count}")
    end

    def import_teacher_rows
      Rails.logger.info("Active Teachers: #{@teacher_importer_rows.count}")
      Teacher.insert_all!(@teacher_importer_rows.map(&:to_h))
      Rails.logger.info("Teachers inserted: #{Teacher.count}")
    end

    def import_induction_periods_rows
      induction_period_rows = []

      @induction_periods_grouped_by_trn.each do |trn, induction_periods|
        induction_periods.each do |ip|
          begin
            ip.teacher_id = teacher_trn_to_id.fetch(trn)
          rescue KeyError
            Rails.logger.error("No teacher found with trn: #{trn}")
            next
          end

          begin
            ip.appropriate_body_id = ab_legacy_id_to_id.fetch(ip.legacy_appropriate_body_id)
          rescue KeyError
            Rails.logger.error("No appropriate body found with legacy_id: #{ip.legacy_appropriate_body_id}")
            next
          end

          induction_period_rows << ip
        end
      end

      induction_period_ids = InductionPeriod.insert_all!(induction_period_rows.map(&:to_record), returning: [:id])
      Rails.logger.info("Induction periods inserted: #{InductionPeriod.count}")

      # FIXME: how do we set titles?
      #        can do it by executing a single line of SQL after insert
      induction_period_rows.each_with_index { |row, i| row.id = induction_period_ids[i]['id'] }

      events = induction_period_rows.flat_map(&:events).flatten

      Event.insert_all(events)
    end

    def import_induction_extensions
      induction_extensions = @teacher_importer_rows.select { |tir| tir.extension_terms.present? }.map do |row|
        {
          teacher_id: teacher_trn_to_id.fetch(row.trn),
          number_of_terms: row.extension_terms
        }
      end

      InductionExtension.insert_all!(induction_extensions)
      Rails.logger.info("Induction extensions inserted: #{InductionExtension.count}")
    end

    def update_event_titles
      statements = [<<~CLAIM, <<~RELEASE]
        update events e
        set heading = t.trs_first_name || ' ' || t.trs_last_name || ' was claimed by ' || ab.name
        from teachers t, appropriate_bodies ab
        where e.event_type = 'appropriate_body_claims_teacher'
        and e.teacher_id = t.id
        and e.appropriate_body_id = ab.id;
      CLAIM
        update events e
        set heading = t.trs_first_name || ' ' || t.trs_last_name || ' was released by ' || ab.name
        from teachers t, appropriate_bodies ab
        where e.event_type = 'appropriate_body_releases_teacher'
        and e.teacher_id = t.id
        and e.appropriate_body_id = ab.id;
      RELEASE

      ActiveRecord::Base.connection.execute(statements.join(';'))
    end

    def insert_admins
      @admin_csv.each do |admin|
        User.create(email: admin['email'], name: admin['name'])
      end
    end
  end
end
