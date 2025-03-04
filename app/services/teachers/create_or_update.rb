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
    Teachers::Create.new(
      trn:,
      trs_first_name:,
      trs_last_name:,
      trs_qts_awarded_on:,
      author:,
      appropriate_body:
    ).create_teacher
  end

  def update_existing_teacher(teacher)
    if author.present? && appropriate_body.present?
      manage = Teachers::Manage.new(author:, teacher:, appropriate_body:)

      name_changed = teacher.trs_first_name != trs_first_name || teacher.trs_last_name != trs_last_name

      if name_changed
        manage.update_name!(
          trs_first_name:,
          trs_last_name:
        )
      end

      manage.update_qts_awarded_on!(
        trs_qts_awarded_on:
      )
    else
      teacher.update!(
        trs_first_name:,
        trs_last_name:,
        trs_qts_awarded_on:
      )
    end

    teacher
  end
end
