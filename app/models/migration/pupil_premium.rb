module Migration
  class PupilPremium < Migration::Base
    self.table_name = :pupil_premiums

    belongs_to :school
  end
end
