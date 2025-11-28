class TeacherHistoryConverter
  def initialize(ecf1_teacher_history:)
    @ecf1_teacher_history = ecf1_teacher_history
  end

  def convert_to_ecf2!
    ECF2TeacherHistory.new.tap do |th|
      # set the name, TRN, etc
      #
      # ecf1_events.each do |event|
      #   add the periods
      # end
    end
  end

private

  def ecf1_events
    @ecf1_teacher_history.induction_records.map do |ir|
      # build some kind of chronological representation of
      # what happened
    end
  end
end
