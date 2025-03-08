module ECTAtSchoolPeriods
  class Search
    attr_reader :scope

    def initialize
      @scope = ECTAtSchoolPeriod.all.order(:created_at)
    end

    def ect_periods(urn: nil, trn: nil)
      where_school_urn_is(urn) if urn
      where_teacher_trn_is(trn) if trn

      @scope
    end

  private

    def where_school_urn_is(urn)
      @scope = scope.joins(:school).where(school: { urn: })
    end

    def where_teacher_trn_is(trn)
      @scope = scope.joins(:teacher).where(teacher: { trn: })
    end
  end
end
