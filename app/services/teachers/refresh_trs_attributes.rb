module Teachers
  class RefreshTRSAttributes
    attr_reader :teacher

    def initialize(teacher)
      @teacher = teacher
    end

    def refresh!
      trs_teacher = TRS::APIClient.new.find_teacher(trn: teacher.trn)

      old_name = Teachers::Name.new(teacher).full_name

      Teacher.transaction do
        teacher.assign_attributes(
          trs_first_name: trs_teacher.first_name,
          trs_last_name: trs_teacher.last_name,
          trs_qts_awarded_on: trs_teacher.qts_awarded_on,
          trs_induction_status: trs_teacher.induction_status,
          trs_qts_status_description: trs_teacher.qts_status_description,
          trs_initial_teacher_training_provider_name: trs_teacher.initial_teacher_training_provider_name,
          trs_initial_teacher_training_end_date: trs_teacher.initial_teacher_training_end_date,
          trs_data_last_refreshed_at: Time.zone.now
        )

        new_name = Teachers::Name.new(teacher).full_name

        if old_name != new_name
          Events::Record.teacher_name_changed_in_trs!(old_name:, new_name:, teacher:, author: Events::SystemAuthor.new)
        end

        teacher.save
      end
    end
  end
end
