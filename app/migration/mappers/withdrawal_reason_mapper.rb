class Mappers::WithdrawalReasonMapper
  def self.ecf2_reason(ecf1_reason)
    # ECF1 reasons:
    # * deceased
    # * left-teaching-profession
    # * mentor-no-longer-being-mentor
    # * moved-school
    # * other
    # * started-in-error
    # * switched-to-school-led
    # * (null)
    #
    # ECF2 reasons:
    # * left_teaching_profession
    # * moved_school
    # * mentor_no_longer_being_mentor
    # * switched_to_school_led
    # * other
    case ecf1_reason
    when "left-teaching-profession" then "left_teaching_profession"
    when "moved-school" then "moved_school"
    when "mentor-no-longer-being-mentor" then "mentor_no_longer_being_mentor"
    when "switched-to-school-led" then "switched_to_school_led"
    else "other"
    end
  end
end
