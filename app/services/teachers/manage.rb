# Perform Teacher edits on behalf of an author and track change events:
#
# 1. first and last name changes
# 2. QTS award date changes (tbc)
# 3. ITT provider name changes (tbc)
#
class Teachers::Manage
  attr_reader :author, :teacher, :appropriate_body

  def initialize(author:, teacher:, appropriate_body:)
    @teacher = teacher
    @appropriate_body = appropriate_body
    @author = author
  end

  def self.find_or_initialize_by(trn:, trs_first_name:, trs_last_name:, event_metadata:)
    teacher = Teacher.find_by(trn:)
    is_new_record = teacher.nil?

    if is_new_record
      teacher = Teacher.new(trn:, trs_first_name:, trs_last_name:)
      teacher.save!
      Events::Record.teacher_created_in_trs!(
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
    @old_name = full_name
    teacher.assign_attributes(trs_first_name:, trs_last_name:)
    @new_name = full_name
    record_name_change_event
    teacher.save!
  end

  def update_qts_awarded_on!(trs_qts_awarded_on:)
    @old_award_date = teacher.trs_qts_awarded_on
    teacher.assign_attributes(trs_qts_awarded_on:)
    @new_award_date = teacher.trs_qts_awarded_on
    record_award_change_event
    teacher.save!
  end

  def update_itt_provider_name!(trs_initial_teacher_training_provider_name:)
    @itt_provider_before = teacher.trs_initial_teacher_training_provider_name
    teacher.assign_attributes(trs_initial_teacher_training_provider_name:)
    @itt_provider_after = teacher.trs_initial_teacher_training_provider_name
    record_itt_provider_change_event
    teacher.save!
  end

private

  attr_reader :new_name, :old_name, :new_award_date, :old_award_date, :itt_provider_before, :itt_provider_after

  def full_name
    ::Teachers::Name.new(teacher).full_name_in_trs
  end

  # State ----------------------------------------------------------------------
  def name_changed?
    new_name != old_name
  end

  def qts_awarded_on_changed?
    new_award_date != old_award_date
  end

  def itt_provider_name_changed?
    itt_provider_after != itt_provider_before
  end

  # Deltas ---------------------------------------------------------------------
  def changed_names
    { old_name:, new_name: }
  end

  def changed_qts_awarded_on
    { old_award_date:, new_award_date: }
  end

  def changed_itt_provider_name
    { itt_provider_before:, itt_provider_after: }
  end

  # Events ---------------------------------------------------------------------
  def record_name_change_event
    return true unless name_changed?

    Events::Record.teacher_name_changed_in_trs!(author:, teacher:, appropriate_body:, **changed_names)
  end

  def record_award_change_event
    return true unless qts_awarded_on_changed?

    Events::Record.qts_awarded_on_changed_in_trs!(author:, teacher:, appropriate_body:, **changed_qts_awarded_on)
  end

  def record_itt_provider_change_event
    return true unless itt_provider_name_changed?

    Events::Record.itt_provider_name_changed_in_trs!(author:, teacher:, appropriate_body:, **changed_itt_provider_name)
  end
end
