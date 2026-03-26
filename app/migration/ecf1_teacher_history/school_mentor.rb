class ECF1TeacherHistory::SchoolMentor
  attr_reader :school,
              :preferred_identity_email,
              :created_at

  def initialize(school:, preferred_identity_email:, created_at:)
    @school = school
    @preferred_identity_email = preferred_identity_email
    @created_at = created_at
  end

  def self.from_hash(hash)
    new(**FactoryBot.attributes_for(:ecf1_school_mentor, **hash))
  end
end
