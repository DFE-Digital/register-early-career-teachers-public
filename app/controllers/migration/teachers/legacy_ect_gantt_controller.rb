module Migration::Teachers
  class LegacyECTGanttController < AdminController
    def show
      teacher = Teacher.find(params[:teacher_id])
      legacy_ect_induction_records = legacy_ect_induction_records(teacher.api_ect_training_record_id)

      send_data(Migration::Gantt.new(legacy_ect_induction_records).to_png, type: "image/png")
    end

  private

    def legacy_ect_induction_records(id)
      return unless id

      Migration::InductionRecordExporter.new.where_ect_participant_profile_id_is(id).rows
    end
  end
end
