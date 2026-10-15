# Prior to 2021 ABs could be Teaching Schools
class SetTeachingSchoolBodyType
  def call
    AppropriateBodyPeriod.transaction do
      teaching_schools.update_all(body_type: "teaching_school")
    end
  end

private

  # Production data has linked only `school_id` for teaching schools
  def teaching_schools
    AppropriateBodyPeriod
      .where.not(school_id: nil)
      .where(teaching_school_hub_id: nil,
             local_authority_id: nil,
             national_body_id: nil)
  end
end
