module Migration
  class LegacyProfileGanttController < AdminController
    def show
      legacy_induction_records = legacy_induction_records(profile_id)
      legacy_declarations = legacy_declarations(profile_id)

      send_data(Migration::PreMigrationGantt.new(legacy_induction_records, legacy_declarations).to_png, type: "image/png")
    end

  private

    def profile_id
      @profile_id ||= safe_params[:profile_id]
    end

    def safe_params
      params.permit(:profile_id)
    end

    def legacy_induction_records(participant_profile_id)
      return unless participant_profile_id

      Migration::InductionRecordExporter.new.where_participant_profile_id_is(participant_profile_id).rows
    end

    def legacy_declarations(participant_profile_id)
      Migration::ParticipantDeclaration.where(participant_profile_id:).order(created_at: :asc)
    end
  end
end
