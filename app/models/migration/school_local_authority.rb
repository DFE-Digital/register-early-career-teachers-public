module Migration
  class SchoolLocalAuthority < Migration::Base
    belongs_to :school
    belongs_to :local_authority

    scope :latest, -> { where(end_year: nil) }
  end
end
