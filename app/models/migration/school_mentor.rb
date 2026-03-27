module Migration
  class SchoolMentor < Migration::Base
    belongs_to :participant_profile
    belongs_to :school
    belongs_to :preferred_identity, class_name: "Migration::ParticipantIdentity"
  end
end
