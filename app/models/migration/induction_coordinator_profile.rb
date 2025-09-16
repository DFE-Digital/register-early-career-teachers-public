module Migration
  class InductionCoordinatorProfile < Migration::Base
    belongs_to :user
    has_many :induction_coordinator_profiles_schools
    has_many :schools, through: :induction_coordinator_profiles_schools
  end
end
