class Mappers::DeferralReasonMapper
  def self.ecf2_reason(ecf1_reason)
    # ECF1 reasons:
    # * bereavement
    # * career-break
    # * long-term-sickness
    # * parental-leave
    # * other
    # * (null)
    #
    # ECF2 reasons:
    # * bereavement
    # * career_break
    # * long_term_sickness
    # * parental_leave
    # * other
    case ecf1_reason
    when "bereavement" then "bereavement"
    when "career-break" then "career_break"
    when "long-term-sickness" then "long_term_sickness"
    when "parental-leave" then "parental_leave"
    else "other"
    end
  end
end
