module Metadata
  class Teacher < Metadata::Base
    self.table_name = :metadata_teachers

    belongs_to :teacher

    validates :teacher, presence: true
    validates :teacher_id, uniqueness: true
    validates :induction_started_on, presence: true, if: -> { induction_finished_on.present? }
    validates :induction_finished_on, comparison: { greater_than: :induction_started_on, allow_nil: true }
  end
end
