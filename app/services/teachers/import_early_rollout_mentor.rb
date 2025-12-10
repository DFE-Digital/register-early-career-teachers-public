module Teachers
  class ImportEarlyRolloutMentor
    EARLY_ROLLOUT_INELIGIBLE_ON = Date.new(2021, 4, 19).freeze

    def initialize(trn:, author: Events::SystemAuthor.new)
      @trn = trn.to_s.strip
      @author = author
    end

    def call
      validate_trn!

      Teacher.transaction do
        teacher = Teacher.find_or_initialize_by(trn:)
        is_new_teacher = teacher.new_record?
        teacher.assign_attributes(early_rollout_attributes)

        if teacher.changed?
          teacher.save!
          record_event(teacher, is_new_teacher:)
          queue_trs_refresh(teacher)
        end

        teacher
      end
    end

  private

    attr_reader :trn, :author

    def validate_trn!
      raise ArgumentError, "TRN must be 7 digits" unless trn.match?(Teacher::TRN_FORMAT)
    end

    def early_rollout_attributes
      {
        mentor_became_ineligible_for_funding_on: EARLY_ROLLOUT_INELIGIBLE_ON,
        mentor_became_ineligible_for_funding_reason: "completed_during_early_roll_out",
      }
    end

    def record_event(teacher, is_new_teacher:)
      Events::Record.teacher_imported_from_dqt_event!(
        author:,
        teacher:,
        body: early_rollout_event_body(is_new_teacher:)
      )
    end

    def early_rollout_event_body(is_new_teacher:)
      if is_new_teacher
        "Teacher created with Early Roll-out mentor attributes during the import"
      else
        "Teacher updated with Early Roll-out mentor attributes during the import"
      end
    end

    def queue_trs_refresh(teacher)
      Teachers::SyncTeacherWithTRSJob.perform_later(teacher:)
    end
  end
end
