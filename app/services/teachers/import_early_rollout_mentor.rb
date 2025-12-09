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
        if teacher.persisted?
          Rails.logger.info("Teacher ##{teacher.id} already exists, skipping Early Roll-out mentor import")
        else
          teacher.assign_attributes(early_rollout_attributes)
          teacher.save!

          record_event(teacher)
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

    def record_event(teacher)
      Events::Record.teacher_imported_from_dqt_event!(
        author:,
        teacher:
      )
    end

    def queue_trs_refresh(teacher)
      Teachers::SyncTeacherWithTRSJob.perform_later(teacher:)
    end
  end
end
