module Teachers
  class MergeTRN
    def initialize(teacher:)
      @teacher = teacher
    end

    def merge!
      return unless eligible_for_merge?

      teacher_started_induction_on = teacher.induction_periods.minimum(:started_on)

      ActiveRecord::Base.transaction do
        move_school_periods
        move_induction_periods
        move_teacher_id_changes
        move_data
        move_mentor_ineligibility_data
        record_teacher_id_change
        refresh_metadata
        record_merge_events
        teacher.destroy!
      end

      if teacher_started_induction_on.present?
        BeginECTInductionJob.perform_now(trn: destination.trn, start_date: teacher_started_induction_on)
      end

      Teachers::SyncTeacherWithTRSJob.perform_later(teacher: destination, wait: 5.minutes)
    end

  private

    attr_reader :teacher

    def destination
      @destination ||= Teacher.find_by_trn(teacher.trs_redirected_to)
    end

    def eligible_for_merge?
      Teachers::MergeTRN::Eligibility.new(teacher:).can_be_merged?
    end

    def overlapping_mentor_at_school_periods
      periods = teacher.mentor_at_school_periods + destination.mentor_at_school_periods

      Teachers::MergeTRN::MentorAtSchoolPeriods::Overlapping.find(periods:)
    end

    def overlapping_ect_at_school_periods
      periods = teacher.ect_at_school_periods + destination.ect_at_school_periods

      Teachers::MergeTRN::ECTAtSchoolPeriods::Overlapping.find(periods:)
    end

    def merge_overlapping_mentor_at_school_periods
      overlapping_mentor_at_school_periods.each do |periods|
        Teachers::MergeTRN::MentorAtSchoolPeriods::Merge.call(periods:, destination:)
      end
    end

    def merge_overlapping_ect_at_school_periods
      overlapping_ect_at_school_periods.each do |periods|
        Teachers::MergeTRN::ECTAtSchoolPeriods::Merge.call(periods:, destination:)
      end
    end

    def move_school_periods
      merge_overlapping_ect_at_school_periods
      merge_overlapping_mentor_at_school_periods

      teacher.ect_at_school_periods.reload.find_each { |period| period.update!(teacher: destination) }
      teacher.mentor_at_school_periods.reload.find_each { |period| period.update!(teacher: destination) }
    end

    def move_induction_periods
      teacher.induction_periods.find_each { |period| period.update!(teacher: destination) }
      teacher.induction_extensions.find_each { |extension| extension.update!(teacher: destination) }
    end

    def move_teacher_id_changes
      teacher.teacher_id_changes.find_each { |change| change.update!(teacher: destination) }
    end

    def move_data
      destination.update_columns(
        ect_first_became_eligible_for_training_at: earliest_date(:ect_first_became_eligible_for_training_at),
        ect_became_ineligible_for_funding_on: earliest_date(:ect_became_ineligible_for_funding_on),
        mentor_first_became_eligible_for_training_at: earliest_date(:mentor_first_became_eligible_for_training_at),
        ect_payments_frozen_year: earliest_date(:ect_payments_frozen_year),
        mentor_payments_frozen_year: earliest_date(:mentor_payments_frozen_year)
      )
    end

    def move_mentor_ineligibility_data
      source_date = teacher.mentor_became_ineligible_for_funding_on
      destination_date = destination.mentor_became_ineligible_for_funding_on

      return if source_date.blank?
      return if destination_date.present? && destination_date <= source_date

      destination.update_columns(
        mentor_became_ineligible_for_funding_on: source_date,
        mentor_became_ineligible_for_funding_reason: teacher.mentor_became_ineligible_for_funding_reason
      )
    end

    def earliest_date(attribute)
      [teacher.public_send(attribute), destination.public_send(attribute)].compact.min
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

    def author
      Events::SystemAuthor.new
    end
  end
end
