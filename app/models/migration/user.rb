module Migration
  class User < Migration::Base
    has_one :teacher_profile
    has_many :participant_identities
  end
end
