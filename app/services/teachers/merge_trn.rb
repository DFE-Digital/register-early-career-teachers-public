module Teachers
  class MergeTRN
    def initialize(teacher:)
      @teacher = teacher
    end

    def merge!
      return unless merge_required?
      return if destination.blank?
      return if any_overlapping_periods?

      ActiveRecord::Base.transaction do
        move_school_periods
        move_induction_records
        move_teacher_id_changes
        record_teacher_id_change
        refresh_metadata
        record_merge_events
        anonymise_teacher
      end

      Teachers::SyncTeacherWithTRSJob.perform_later(teacher: destination)
    end

  private

    attr_reader :teacher

    def destination
      @destination || Teacher.find_by_trn(teacher.trs_redirected_to)
    end

    def merge_required?
      teacher.trs_response == "permanent_redirect" && teacher.trs_redirected_to.present?
    end

    delegate :any_overlapping_periods?, to: :overlapping

    def overlapping
      Teachers::Overlapping.new(teacher:, other_teacher: destination)
    end

    def move_school_periods
      teacher.ect_at_school_periods.find_each { |period| period.update!(teacher: destination) }
      teacher.mentor_at_school_periods.find_each { |period| period.update!(teacher: destination) }
    end

    def move_induction_records
      teacher.induction_periods.find_each { |period| period.update!(teacher: destination) }
      teacher.induction_extensions.find_each { |extension| extension.update!(teacher: destination) }
    end

    def move_teacher_id_changes
      teacher.teacher_id_changes.find_each { |change| change.update!(teacher: destination) }
    end

    def record_teacher_id_change
      TeacherIdChange.create!(
        teacher: destination,
        api_from_teacher_id: teacher.api_id,
        api_to_teacher_id: destination.api_id
      )
    end

    # The declarative refresh hook only re-points the destination's metadata on
    # reassignment, so refresh the destination explicitly and tear down the
    # stale source rows so their latest_*_training_period_id FKs don't dangle
    def refresh_metadata
      teacher.lead_provider_metadata.destroy_all
      Metadata::Manager.new.refresh_metadata!([destination])
    end

    def record_merge_events
      Events::Record.record_teacher_trn_merged_events!(author:, source: teacher, destination:)
    end

    def anonymise_teacher
      Teachers::Anonymise.new(teacher: teacher.reload, reason: :teacher_record_merged).anonymise!
    end

    def author
      Events::SystemAuthor.new
    end
  end
end
