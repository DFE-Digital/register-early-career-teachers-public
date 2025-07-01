module Migration
  class ParticipantIdentity < Migration::Base
    belongs_to :user
    has_many :participant_profiles
  end
end
