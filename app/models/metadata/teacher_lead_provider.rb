module Metadata
  class TeacherLeadProvider < Metadata::Base
    self.table_name = :metadata_teacher_lead_providers

    belongs_to :teacher
    belongs_to :lead_provider

    validates :teacher, presence: true
    validates :lead_provider, presence: true
    validates :teacher_id, uniqueness: { scope: :lead_provider_id }
  end
end
