module DataFixes
  # FIXME: this doesn't account for groups so will set the first of each group
  def earliest_initial_start_date(induction_record:)
    [induction_record.start_date, induction_record.created_at].min
  end
end
