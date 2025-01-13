module ECTAtSchoolPeriods
  class Search
    def exists?(school_id:, trn:)
      ECTAtSchoolPeriod.joins(:teacher)
                       .where(teachers: { trn: }, school_id:)
                       .exists?
    end
  end
end
