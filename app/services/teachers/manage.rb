# Perform teacher record edits on behalf of author and track change events
# 
# 1. first and last name changes
# 2. award date changes
#
class Teachers::Manage
  attr_reader :author, :teacher, :teacher, :old_name, :new_name

  def initialize(author, teacher)
    @author = author
    @teacher = teacher
  end

  def update!(params)
    @old_name = full_name
    # @old_award_date = teacher.trs_qts_awarded_on
    teacher.assign_attributes(params)
    @new_name = full_name
    record_name_change_event

    # @new_award_date = teacher.trs_qts_awarded_on
    # record_award_change_event
    teacher.save!
  end

  # separate methods -----------------------------------------------------------

  # def set_trs_name(trs_first_name, trs_last_name)
  #   @old_name = full_name
  #   teacher.assign_attributes(trs_first_name:, trs_last_name:)
  #   @new_name = full_name
  #   teacher.save!
  #   self
  # end

  # def set_trs_qts_awarded_on(trs_qts_awarded_on)
  #   teacher.assign_attributes(trs_qts_awarded_on:)
  #   teacher.save!
  #   self
  # end

  # other methods -----------------------------------------------------------

private

  def name_changed?
    return false if old_name.nil?

    new_name != old_name
  end

  def qts_awarded_on_changed?
    return false if teacher.trs_qts_awarded_on.nil?

    @new_award_date != @old_award_date
  end

  def changed_names
    { old_name:, new_name: }
  end

  # def changed_qts_awarded_on
  #   { old_award_date:, new_award_date: }
  # end

  def record_name_change_event
    return true unless name_changed?

    Events::Record.teacher_name_changed_in_trs!(author:, teacher:, appropriate_body:, **changed_names)
  end

  def record_award_change_event
    true unless qts_awarded_on_changed?

    # Events::Record.qts_awarded_on_changed_in_trs!(author:, teacher:, appropriate_body:, **manage_teacher.changed_qts_awarded_on)
  end

  # def teacher_params
  #   pending_induction_submission.attributes.symbolize_keys.slice(*editable_teacher_params)
  # end

  # def editable_teacher_params
  #   %i[trs_first_name trs_last_name trs_qts_awarded_on]
  # end

  def full_name
    ::Teachers::Name.new(teacher).full_name_in_trs
  end
end
