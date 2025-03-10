module Teachers
  class RefreshTRSAttributes
    attr_reader :teacher

    def initialize(teacher)
      @teacher = teacher
    end

    def refresh!
      Teacher.transaction do
        manage_teacher.update_name!(trs_first_name: trs_teacher.first_name, trs_last_name: trs_teacher.last_name)
        manage_teacher.update_qts_awarded_on!(trs_qts_awarded_on: trs_teacher.qts_awarded_on)
        manage_teacher.update_itt_provider_name!(trs_initial_teacher_training_provider_name: trs_teacher.initial_teacher_training_provider_name)
        manage_teacher.update_trs_induction_status!(trs_induction_status: trs_teacher.induction_status)

        teacher.assign_attributes(
          trs_qts_status_description: trs_teacher.qts_status_description,
          trs_initial_teacher_training_provider_name: trs_teacher.initial_teacher_training_provider_name,
          trs_initial_teacher_training_end_date: trs_teacher.initial_teacher_training_end_date,
          trs_data_last_refreshed_at: Time.zone.now
        )

        teacher.save
      end
    end

  private

    def trs_teacher
      @trs_teacher ||= TRS::APIClient.new.find_teacher(trn: teacher.trn)
    end

    def manage_teacher
      @manage_teacher ||= Teachers::Manage.new(teacher:, author:, appropriate_body: nil)
    end

    def author
      @author ||= Events::SystemAuthor.new
    end
  end
end
