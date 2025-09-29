module Metadata
  class Teacher < Metadata::Base
    self.table_name = :metadata_teachers

    belongs_to :teacher

    validates :teacher, presence: true
    validates :teacher_id, uniqueness: true
    validates :first_became_eligible_for_ect_training_at, immutable_once_set: true
    validates :first_became_eligible_for_mentor_training_at, immutable_once_set: true
  end
end
