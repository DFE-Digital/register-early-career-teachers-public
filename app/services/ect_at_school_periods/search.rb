module ECTAtSchoolPeriods
  class Search
    def exists?(school_id:, trn:)
      ECTAtSchoolPeriod.joins(:teacher)
                       .where(teachers: { trn: }, school_id:)
                       .ongoing
                       .exists?
    end
  end
end
