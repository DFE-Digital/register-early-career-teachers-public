module Migration
  class LocalAuthority < Migration::Base
    has_many :school_local_authorities
    has_many :schools, through: :school_local_authorities
  end
end
