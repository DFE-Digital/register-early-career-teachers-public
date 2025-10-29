module Migration
  class ParticipantDeclaration < Migration::Base
    belongs_to :participant_profile

    self.inheritance_column = :ignore
  end
end
