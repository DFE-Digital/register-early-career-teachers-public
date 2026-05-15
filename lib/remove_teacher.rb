# Remove teacher training records
#
class RemoveTeacher
  attr_reader :teacher

  # @param teacher_id [Integer]
  def initialize(teacher_id)
    @teacher = Teacher.find(teacher_id)
  end

  # @return [Teacher, false]
  def call
    Teacher.transaction do
      destroy_has_many!
      teacher.destroy! or raise(ActiveRecord::Rollback)
    end

    teacher
  rescue ActiveRecord::Rollback,
         ActiveRecord::InvalidForeignKey,
         ActiveRecord::StatementInvalid => e
    Rails.logger.debug e.message
    false
  end

  # @return [Array<Symbol>]
  def has_many_associations
    Teacher.reflect_on_all_associations(:has_many).map(&:name).sort
  end

private

  def destroy_has_many!
    has_many_associations.each do |assoc|
      records = teacher.send(assoc)

      if records.any?
        Rails.logger.debug "Destroying #{records.count} #{assoc}"
        teacher.send(assoc).destroy_all
      end
    end
  end
end
