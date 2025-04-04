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
      @old_name = full_name
      teacher.assign_attributes(trs_first_name:, trs_last_name:)
      @new_name = full_name
      record_name_change_event
      teacher.save!
    end
  end

  def update_qts_awarded_on!(trs_qts_awarded_on:)
    Teacher.transaction do
      @old_award_date = teacher.trs_qts_awarded_on
      teacher.assign_attributes(trs_qts_awarded_on:)
      @new_award_date = teacher.trs_qts_awarded_on
      record_award_change_event
      teacher.save!
    end
  end

  def update_itt_provider_name!(trs_initial_teacher_training_provider_name:)
    Teacher.transaction do
      @itt_provider_before = teacher.trs_initial_teacher_training_provider_name
      teacher.assign_attributes(trs_initial_teacher_training_provider_name:)
      @itt_provider_after = teacher.trs_initial_teacher_training_provider_name
      teacher.save!
    end
  end

  def update_trs_induction_status!(trs_induction_status:)
    Teacher.transaction do
      @induction_status_before = teacher.trs_induction_status
      teacher.assign_attributes(trs_induction_status:)
      @induction_status_after = teacher.trs_induction_status
      record_induction_status_change_event
      teacher.save!
    end
  end

  def update_trs_attributes!(trs_qts_status_description:, trs_qts_awarded_on:, trs_initial_teacher_training_provider_name:, trs_initial_teacher_training_end_date:, trs_data_last_refreshed_at:)
    Teacher.transaction do
      teacher.assign_attributes(
        trs_qts_status_description:,
        trs_qts_awarded_on:,
        trs_initial_teacher_training_provider_name:,
        trs_initial_teacher_training_end_date:,
        trs_data_last_refreshed_at:
      )
      record_teacher_trs_attribute_update(modifications: teacher.changes)
      teacher.save!
    end
  end

private

  attr_reader :new_name, :old_name, :new_award_date, :old_award_date, :old_induction_status, :new_induction_status

  def full_name
    ::Teachers::Name.new(teacher).full_name_in_trs
  end

  # State ----------------------------------------------------------------------
  def name_changed?
    return false if old_name.nil?

    new_name != old_name
  end

  def qts_awarded_on_changed?
    return false if teacher.trs_qts_awarded_on.nil?

    new_award_date != old_award_date
  end

  def induction_status_changed?
    induction_status_before != induction_status_after
  end

  # Deltas ---------------------------------------------------------------------
  def changed_names
    { old_name:, new_name: }
  end

  def changed_qts_awarded_on
    { old_award_date:, new_award_date: }
  end

  def changed_status
    { old_induction_status:, new_induction_status: }
  end

  # Events ---------------------------------------------------------------------
  def record_name_change_event
    return true unless name_changed?

    Events::Record.teacher_name_changed_in_trs!(author:, teacher:, appropriate_body:, **changed_names)
  end

  # TODO: implement tracking award changes?
  def record_award_change_event
    return true unless qts_awarded_on_changed?

    :no_op
    # Events::Record.qts_awarded_on_changed_in_trs!(author:, teacher:, appropriate_body:, **manage_teacher.changed_qts_awarded_on)
  end

  def record_induction_status_change_event
    Events::Record.teacher_induction_status_changed_in_trs!(author:, teacher:, appropriate_body:, **changed_status)
  end

  def record_teacher_trs_attribute_update(modifications:)
    Events::Record.teacher_attributes_updated_from_trs!(author:, teacher:, modifications:)
  end
end
