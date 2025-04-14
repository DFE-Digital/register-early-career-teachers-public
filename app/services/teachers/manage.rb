# Perform Teacher edits on behalf of an author and track change events:
#
# 1. first and last name changes
# 2. QTS award date changes (tbc)
# 3. ITT provider name changes (tbc)
#
class Teachers::Manage
  attr_reader :author, :teacher, :appropriate_body

  def initialize(author:, teacher:, appropriate_body:)
    @author = author
    @teacher = teacher
    @appropriate_body = appropriate_body
  end

  def self.find_or_initialize_by(trn:, trs_first_name:, trs_last_name:, event_metadata:)
    teacher = Teacher.find_or_initialize_by(trn:) do |t|
      t.trs_first_name = trs_first_name
      t.trs_last_name = trs_last_name
    end

    if teacher.new_record? && teacher.save
      Events::Record.teacher_imported_from_trs!(
        author: event_metadata[:author],
        teacher:,
        appropriate_body: event_metadata[:appropriate_body]
      )
    end

    new(
      author: event_metadata[:author],
      teacher:,
      appropriate_body: event_metadata[:appropriate_body]
    )
  end

  def update_name!(trs_first_name:, trs_last_name:)
    Teacher.transaction do
      old_name = full_name
      teacher.assign_attributes(trs_first_name:, trs_last_name:)
      new_name = full_name
      record_name_change_event(old_name, new_name)
      teacher.save!
    end
  end

  # FIXME: remove this method, there's no custom event for changing the QTS
  #        award date so it doesn't need special treatment
  def update_qts_awarded_on!(trs_qts_awarded_on:)
    Teacher.transaction do
      @old_award_date = teacher.trs_qts_awarded_on
      teacher.assign_attributes(trs_qts_awarded_on:)
      @new_award_date = teacher.trs_qts_awarded_on
      teacher.save!
    end
  end

  # FIXME: remove this method, there's no custom event for changing the ITT
  #        provider name
  def update_itt_provider_name!(trs_initial_teacher_training_provider_name:)
    Teacher.transaction do
      teacher.assign_attributes(trs_initial_teacher_training_provider_name:)
      teacher.save!
    end
  end

  def update_trs_induction_status!(trs_induction_status:)
    Teacher.transaction do
      old_induction_status = teacher.trs_induction_status
      teacher.assign_attributes(trs_induction_status:)
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

private

  def full_name
    ::Teachers::Name.new(teacher).full_name_in_trs
  end

  # Events ---------------------------------------------------------------------
  def record_name_change_event(old_name, new_name)
    return if old_name == new_name

    Events::Record.teacher_name_changed_in_trs!(author:, teacher:, appropriate_body:, old_name:, new_name:)
  end

  def record_induction_status_change_event(old_induction_status, new_induction_status)
    return if old_induction_status == new_induction_status

    Events::Record.teacher_induction_status_changed_in_trs!(author:, teacher:, appropriate_body:, old_induction_status:, new_induction_status:)
  end

  def record_teacher_trs_attribute_update(modifications:)
    Events::Record.teacher_attributes_updated_from_trs!(author:, teacher:, modifications:)
  end
end
