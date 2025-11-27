module Migration
  class ParticipantDeclaration < Migration::Base
    belongs_to :participant_profile
    belongs_to :cpd_lead_provider
    belongs_to :cohort

    self.inheritance_column = :ignore
  end
end
