module Migration
  class SchoolCohort < Migration::Base
    belongs_to :school
    belongs_to :cohort
    has_many :induction_programmes
    belongs_to :appropriate_body
    belongs_to :default_induction_programme, class_name: "Migration::InductionProgramme", optional: true
  end
end
