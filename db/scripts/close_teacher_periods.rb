# Close at_school, training and mentorship periods for the teachers in the list of trns
#
def close_teacher_periods(trns:, author_email:, finished_on: Date.current)
  ActiveRecord::Base.transaction do
    author = Sessions::Users::DfEUser.new(email: author_email)

    trns.each do |trn|
      teacher = Teacher.find_by!(trn:)

      # ect_at_school_periods + associated periods
      teacher.ect_at_school_periods.ongoing.each do |period|
        ECTAtSchoolPeriods::Finish.new(ect_at_school_period: period, finished_on:, author:).finish!
      end

      # mentor_at_school_periods + associated periods
      MentorAtSchoolPeriods::Finish.new(teacher:, finished_on:, author:).finish_existing_at_school_periods!
    end
  end
end
