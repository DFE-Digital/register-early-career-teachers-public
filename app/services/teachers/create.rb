class Teachers::Create
  attr_reader :trn, :trs_first_name, :trs_last_name, :trs_qts_awarded_on, :author, :appropriate_body

  def initialize(trn:, trs_first_name:, trs_last_name:, trs_qts_awarded_on:, author: nil, appropriate_body: nil)
    @trn = trn
    @trs_first_name = trs_first_name
    @trs_last_name = trs_last_name
    @trs_qts_awarded_on = trs_qts_awarded_on
    @author = author
    @appropriate_body = appropriate_body
  end

  def create_teacher
    teacher = Teacher.create!(
      trn:,
      trs_first_name:,
      trs_last_name:,
      trs_qts_awarded_on:
    )

    record_teacher_created_event(teacher) if author.present? && appropriate_body.present?

    teacher
  end

private

  def record_teacher_created_event(teacher)
    Events::Record.new(
      author:,
      event_type: :teacher_record_created,
      heading: "Teacher record created for #{full_name(teacher)}",
      happened_at: Time.zone.now,
      teacher:,
      appropriate_body:
    ).record_event!
  end

  def full_name(teacher)
    ::Teachers::Name.new(teacher).full_name_in_trs
  end
end
