module Teachers
  class RefreshTRSAttributes
    attr_reader :teacher

    def initialize(teacher)
      @teacher = teacher
    end

    def refresh!
      # In some environments (e.g. sandbox) we don't want to allow data in TRS to
      # overwrite existing teacher data, so we skip the refresh.
      return unless Rails.application.config.enable_trs_teacher_refresh

      trs_teacher = TRS::APIClient.build.find_teacher(trn: teacher.trn)

      Teacher.transaction do
        manage_teacher.update_name!(trs_first_name: trs_teacher.first_name, trs_last_name: trs_teacher.last_name)
        manage_teacher.update_trs_induction_status!(trs_induction_status: trs_teacher.induction_status)

        manage_teacher.update_trs_attributes!(
          trs_qts_status_description: trs_teacher.qts_status_description,
          trs_qts_awarded_on: trs_teacher.qts_awarded_on,
          trs_initial_teacher_training_provider_name: trs_teacher.initial_teacher_training_provider_name,
          trs_initial_teacher_training_end_date: trs_teacher.initial_teacher_training_end_date,
          trs_data_last_refreshed_at: Time.zone.now
        )

        teacher.save
      end
    rescue TRS::Errors::TeacherDeactivated
      Teacher.transaction do
        manage_teacher.mark_teacher_as_deactivated!(trs_data_last_refreshed_at: Time.zone.now)
      end
    end

  private

    def manage_teacher
      @manage_teacher ||= Teachers::Manage.new(teacher:, author:, appropriate_body: nil)
    end

    def author
      @author ||= Events::SystemAuthor.new
    end
  end
end
