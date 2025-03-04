class Teachers::CreateOrUpdate
  attr_reader :trn, :trs_first_name, :trs_last_name, :trs_qts_awarded_on, :author, :appropriate_body

  def initialize(trn:, trs_first_name:, trs_last_name:, trs_qts_awarded_on:, author: nil, appropriate_body: nil)
    @trn = trn
    @trs_first_name = trs_first_name
    @trs_last_name = trs_last_name
    @trs_qts_awarded_on = trs_qts_awarded_on
    @author = author
    @appropriate_body = appropriate_body
  end

  def create_or_update
    ActiveRecord::Base.transaction do
      teacher = Teacher.find_by(trn:)

      if teacher.present?
        update_existing_teacher(teacher)
      else
        create_new_teacher
      end
    end
  end

private

  def create_new_teacher
    teacher = Teacher.create!(
      trn:,
      trs_first_name:,
      trs_last_name:,
      trs_qts_awarded_on:
    )

    record_teacher_created_event(teacher) if author.present? && appropriate_body.present?

    teacher
  end

  def update_existing_teacher(teacher)
    name_changed = teacher.trs_first_name != trs_first_name || teacher.trs_last_name != trs_last_name

    if name_changed
      old_name = Teachers::Name.new(teacher).full_name_in_trs

      teacher.update!(
        trs_first_name:,
        trs_last_name:,
        trs_qts_awarded_on:
      )

      record_name_change_event(teacher, old_name) if author.present? && appropriate_body.present?
    else
      teacher.update!(trs_qts_awarded_on:)
    end

    teacher
  end

  def record_teacher_created_event(teacher)
    Events::Record.new(
      author:,
      event_type: :teacher_record_created,
      heading: "Teacher record created for #{Teachers::Name.new(teacher).full_name_in_trs}",
      happened_at: Time.zone.now,
      teacher:,
      appropriate_body:
    ).record_event!
  end

  def record_name_change_event(teacher, old_name)
    new_name = Teachers::Name.new(teacher).full_name_in_trs

    Events::Record.teacher_name_changed_in_trs!(
      old_name:,
      new_name:,
      author:,
      teacher:,
      appropriate_body:
    )
  end
end
