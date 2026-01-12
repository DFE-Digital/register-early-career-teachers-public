# Perform Teacher edits on behalf of an author and track change events:
#
# 1. teacher name changes
# 2. induction status and date changes
# 3. QTS and ITT changes
# 4. teacher deactivation
#
# @see Teachers::Manageable
class Teachers::Manage
  class AlreadyDeactivated < StandardError; end

  attr_reader :author, :teacher, :appropriate_body

  def initialize(author:, teacher:, appropriate_body:)
    @author = author
    @teacher = teacher
    @appropriate_body = appropriate_body
  end

  private_class_method :new

  def self.system_update(teacher:)
    new(teacher:, author: Events::SystemAuthor.new, appropriate_body: nil)
  end

  def self.find_or_initialize_by(trn:, trs_first_name:, trs_last_name:, event_metadata:)
    teacher = Teacher.find_or_initialize_by(trn:) do |t|
      t.trs_first_name = trs_first_name
      t.trs_last_name = trs_last_name
    end

    if teacher.new_record? && teacher.save
      Events::Record.teacher_imported_from_trs_event!(teacher:, **event_metadata)
    end

    new(teacher:, **event_metadata)
  end

  def update_name!(trs_first_name:, trs_last_name:)
    Teacher.transaction do
      old_name = full_name
      teacher.assign_attributes(trs_first_name:, trs_last_name:)
      new_name = full_name

      # Clear `corrected_name` if new trs name matches it
      if teacher.corrected_name.to_s.squish == new_name.to_s.squish
        teacher.assign_attributes(corrected_name: nil)
      end

      record_name_change_event(old_name, new_name)
      teacher.save!
    end
  end

  # TODO: log induction date changes in status event
  def update_trs_induction_status!(trs_induction_status:, trs_induction_start_date:, trs_induction_completed_date:)
    Teacher.transaction do
      old_induction_status = teacher.trs_induction_status
      teacher.assign_attributes(
        trs_induction_status:,
        trs_induction_start_date:,
        trs_induction_completed_date:
      )
      new_induction_status = teacher.trs_induction_status

      record_induction_status_change_event(old_induction_status, new_induction_status)
      teacher.save!
    end
  end

  def update_trs_attributes!(trs_qts_status_description:, trs_qts_awarded_on:, trs_initial_teacher_training_provider_name:, trs_initial_teacher_training_end_date:, trs_data_last_refreshed_at:)
    Teacher.transaction do
      teacher.assign_attributes(
        trs_qts_status_description:,
        trs_qts_awarded_on:,
        trs_initial_teacher_training_provider_name:,
        trs_initial_teacher_training_end_date:
      )

      record_teacher_trs_attribute_update(modifications: teacher.changes)

      teacher.trs_data_last_refreshed_at = trs_data_last_refreshed_at
      teacher.save!
    end
  end

  def mark_teacher_as_deactivated!(trs_data_last_refreshed_at:)
    fail(AlreadyDeactivated) if teacher.trs_deactivated?

    Teacher.transaction do
      teacher.update!(trs_deactivated: true, trs_data_last_refreshed_at:)
      record_teacher_deactivated_event
    end
  end

  def mark_teacher_as_not_found!(trs_data_last_refreshed_at:)
    Teacher.transaction do
      induction = teacher.finished_induction_period

      teacher.update!(
        trs_data_last_refreshed_at:,
        trs_not_found: true,
        trs_induction_status: INDUCTION_OUTCOMES[induction&.outcome&.to_sym],
        trs_induction_start_date: induction&.started_on,
        trs_induction_completed_date: induction&.finished_on
      )
    end
  end

private

  def full_name
    ::Teachers::Name.new(teacher).full_name_in_trs
  end

  # Events ---------------------------------------------------------------------
  def record_name_change_event(old_name, new_name)
    return if old_name == new_name

    Events::Record.teacher_name_changed_in_trs_event!(author:, teacher:, appropriate_body:, old_name:, new_name:)
  end

  def record_induction_status_change_event(old_induction_status, new_induction_status)
    return if old_induction_status == new_induction_status

    Events::Record.teacher_induction_status_changed_in_trs_event!(author:, teacher:, appropriate_body:, old_induction_status:, new_induction_status:)
  end

  def record_teacher_trs_attribute_update(modifications:)
    return if modifications.empty?

    Events::Record.teacher_trs_attributes_updated_event!(author:, teacher:, modifications:)
  end

  def record_teacher_deactivated_event
    Events::Record.record_teacher_trs_deactivated_event!(author:, teacher:)
  end
end
