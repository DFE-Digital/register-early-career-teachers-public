class TeacherIdChange < ApplicationRecord
  include DeclarativeUpdates

  belongs_to :teacher

  validates :teacher, :api_from_teacher_id, :api_to_teacher_id, presence: true

  # Only needed for migrating data from ECF; can be removed later.
  validates :ecf_id, uniqueness: { case_sensitive: false, message: "ECF id already exists for another teacher id change" }, allow_nil: true

  touch -> { teacher }, on_event: %i[create update destroy], timestamp_attribute: :api_updated_at, when_changing: %i[api_from_teacher_id api_to_teacher_id created_at]
end
