module API::FindTeacher
  extend ActiveSupport::Concern

  TEACHER_TYPES = %i[ect mentor].freeze

  included do
    validates :teacher_api_id, presence: { message: "Enter a '#/teacher_api_id'." }
    validate :teacher_exists
    validates :teacher_type, presence: { message: "Enter a '#/teacher_type'." }
    validates :teacher_type,
              inclusion: {
                in: TEACHER_TYPES,
                message: "The entered '#/teacher_type' is not recognised for the given participant. Check details and try again."
              },
              allow_blank: true
    validate :teacher_type_exists
  end

private

  def teacher
    @teacher ||= Teacher.find_by(api_id: teacher_api_id) if teacher_api_id
  end

  def teacher_exists
    return if errors.any?
    return if teacher

    errors.add(:teacher_api_id, "Your update cannot be made as the '#/teacher_api_id' is not recognised. Check participant details and try again.")
  end

  def teacher_type_exists
    return if errors.any?
    return if training_period

    errors.add(:teacher_type, "The entered '#/teacher_type' is not recognised for the given participant. Check details and try again.")
  end
end
