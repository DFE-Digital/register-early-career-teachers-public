# @param operator [AppropriateBodyPeriod, TeachingSchoolHub, NationalBody, LocalAuthority, School]
# @return [AppropriateBodyPeriod]
def appropriate_body_period_for(operator)
  case operator
  when AppropriateBodyPeriod then operator
  when TeachingSchoolHub, NationalBody then find_period_displayed_as(operator.name)
  when LocalAuthority then operator.appropriate_body_period
  when School then AppropriateBodyPeriod.teaching_school.find_by!(school_id: operator)
  else
    raise ArgumentError, "not an appropriate body: #{operator.inspect}"
  end
end

# @param name [String] the operating name of an appropriate body
# @return [AppropriateBodyPeriod]
def find_period_displayed_as(name)
  AppropriateBodyPeriod.with_display_name(name).first ||
    raise(ActiveRecord::RecordNotFound, "no appropriate body is named #{name.inspect}")
end
