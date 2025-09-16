module Migration
  class InductionCoordinatorProfilesSchool < Migration::Base
    belongs_to :induction_coordinator_profile
    belongs_to :school
  end
end
