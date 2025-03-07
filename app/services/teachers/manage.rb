# Perform Teacher edits on behalf of an author and track change events:
#
# 1. Updating teacher attributes
# 2. Creating events for tracked changes (e.g., name changes)
# 3. Creating events for new teacher records
#
class Teachers::Manage
  attr_reader :author, :teacher, :appropriate_body

  def initialize(author:, teacher:, appropriate_body:)
    @author = author
    @teacher = teacher
    @appropriate_body = appropriate_body
  end

  # Updates a teacher record with the provided attributes and creates appropriate events
  def update_teacher!(attributes)
    if teacher.new_record?
      update_and_save_teacher(attributes)
      record_teacher_creation_event
    else
      capture_old_values(attributes)
      update_and_save_teacher(attributes)
      record_change_events(attributes)
    end

    teacher
  end

private

  attr_reader :new_name, :old_name, :new_award_date, :old_award_date

  # Updates the teacher with the provided attributes and saves the record
  def update_and_save_teacher(attributes)
    teacher.assign_attributes(attributes)
    teacher.save!
  end

  # Captures the old values before updating the teacher record
  def capture_old_values(attributes)
    if name_attributes_changing?(attributes)
      @old_name = current_full_name
    end

    if qts_award_date_changing?(attributes)
      @old_award_date = teacher.trs_qts_awarded_on_was
    end
  end

  # Records events for changes to the teacher record
  def record_change_events(attributes)
    if name_attributes_changing?(attributes)
      @new_name = current_full_name
      record_name_change_event
    end

    if qts_award_date_changing?(attributes)
      @new_award_date = teacher.trs_qts_awarded_on
      record_award_change_event
    end
  end

  # Records an event for a new teacher record
  def record_teacher_creation_event
    Events::Record.teacher_record_created!(
      author:,
      teacher:,
      appropriate_body:,
      trn: teacher.trn
    )
  end

  # Gets the current full name of the teacher
  def current_full_name
    ::Teachers::Name.new(teacher).full_name_in_trs
  end

  # Checks if name attributes are changing
  def name_attributes_changing?(attributes)
    attributes.key?(:trs_first_name) || attributes.key?(:trs_last_name)
  end

  # Checks if QTS award date is changing
  def qts_award_date_changing?(attributes)
    attributes.key?(:trs_qts_awarded_on)
  end

  # Checks if the name has changed
  def name_changed?
    return false if old_name.nil? || new_name.nil?

    old_name.to_s != new_name.to_s
  end

  # Checks if the QTS award date has changed
  def qts_awarded_on_changed?
    return false if teacher.trs_qts_awarded_on.nil?

    new_award_date != old_award_date
  end

  # Records an event for a name change
  def record_name_change_event
    return true unless name_changed?

    Events::Record.teacher_name_changed_in_trs!(
      old_name:,
      new_name:,
      author:,
      teacher:,
      appropriate_body:
    )
  end

  # Records an event for a QTS award date change
  def record_award_change_event
    return true unless qts_awarded_on_changed?

    Events::Record.teacher_qts_awarded_on_changed_in_trs!(
      old_award_date:,
      new_award_date:,
      author:,
      teacher:,
      appropriate_body:
    )
  end
end
