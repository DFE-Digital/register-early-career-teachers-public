module AppropriateBodies::Importers
  class Importer
    # rubocop:disable Rails/Output
    def initialize(appropriate_body_csv, teachers_csv, induction_period_csv)
      induction_periods_grouped_by_trn = InductionPeriodImporter.new(induction_period_csv).periods_by_trn

      active_teachers = induction_periods_grouped_by_trn.keys
      teacher_importer_rows = TeacherImporter.new(teachers_csv, active_teachers).rows

      active_abs = induction_periods_grouped_by_trn.flat_map { |_trn, ips| ips.map(&:legacy_appropriate_body_id) }.uniq
      ab_importer_rows = AppropriateBodyImporter.new(appropriate_body_csv, active_abs).rows

      puts "Active appropriate bodies: #{active_abs.count}"

      AppropriateBody.insert_all(ab_importer_rows.select { |r| r.legacy_id.in?(active_abs) }.map(&:to_h))
      puts "Appropriate bodies inserted: #{AppropriateBody.count}"

      puts "Active Teachers: #{teacher_importer_rows.count}"

      Teacher.insert_all(teacher_importer_rows.map(&:to_h))
      puts "Teachers inserted: #{Teacher.count}"

      # TODO: insert induction periods
      teacher_trn_to_id = Teacher.all.select(:id, :trn).each_with_object({}) do |t, h|
        h[t[:trn]] = t[:id]
      end

      ab_legacy_id_to_id = AppropriateBody.all.select(:id, :legacy_id).each_with_object({}) do |ab, h|
        h[ab[:legacy_id]] = ab[:id]
      end

      induction_period_rows = []

      induction_periods_grouped_by_trn.each do |trn, induction_periods|
        induction_periods.each do |ip|
          begin
            ip.teacher_id = teacher_trn_to_id.fetch(trn)
          rescue KeyError
            puts "No teacher found with trn: #{trn}"
            next
          end

          begin
            ip.appropriate_body_id = ab_legacy_id_to_id.fetch(ip.legacy_appropriate_body_id)
          rescue KeyError
            puts "No appropriate body found with legacy_id: #{ip.legacy_appropriate_body_id}"
            next
          end

          induction_period_rows << ip
        end
      end

      InductionPeriod.insert_all(induction_period_rows.map(&:to_record))

      induction_extensions = teacher_importer_rows.select { |tir| tir.extension_terms.present? }.map do |row|
        {
          teacher_id: teacher_trn_to_id.fetch(row.trn),
          number_of_terms: row.extension_terms
        }
      end

      InductionExtension.insert_all(induction_extensions)
      puts "Induction extensions inserted: #{InductionExtension.count}"

      # TODO: insert events

      binding.debugger
    end
    # rubocop:enable Rails/Output
  end
end
