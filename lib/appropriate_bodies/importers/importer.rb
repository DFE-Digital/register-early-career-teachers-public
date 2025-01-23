module AppropriateBodies::Importers
  class Importer
    def initialize(appropriate_body_csv, teachers_csv, induction_period_csv)
      # ab_importer_rows = AppropriateBodyImporter.new(appropriate_body_csv).rows
      # teacher_importer_rows = TeacherImporter.new(teachers_csv).rows
      induction_periods_grouped_by_trn = InductionPeriodImporter.new(induction_period_csv).periods_by_trn

      true

      binding.debugger
      # get induction periods grouped by TRN
      #
    end
  end
end
