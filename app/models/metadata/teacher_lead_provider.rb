module Metadata
  class TeacherLeadProvider < Metadata::Base
    self.table_name = :metadata_teacher_lead_providers

    belongs_to :teacher
    belongs_to :lead_provider

    belongs_to :latest_ect_training_period, optional: true, class_name: "TrainingPeriod"
    belongs_to :latest_mentor_training_period, optional: true, class_name: "TrainingPeriod"

    validates :teacher, presence: true
    validates :lead_provider, presence: true
  end
end
