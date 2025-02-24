module Teachers
  class Search
    attr_reader :scope

    def initialize(query_string: :ignore, appropriate_bodies: :ignore)
      @scope = Teacher.all

      where_appropriate_bodies_in(appropriate_bodies)
      matching(query_string)
    end

    def search
      scope.order(:trs_last_name, :trs_first_name, :id)
    end

  private

    def matching(query_string)
      return if query_string == :ignore
      return if query_string.nil?

      trns = query_string.scan(%r(\d{7}))

      (trns.any?) ? with_trns(trns) : where_query_matches(query_string)
    end

    def where_appropriate_bodies_in(appropriate_bodies)
      return if appropriate_bodies == :ignore

      @scope
        .merge!(@scope.joins(:appropriate_bodies).where(induction_periods: { appropriate_body: appropriate_bodies }))
        .merge!(::InductionPeriod.ongoing)
    end

    def with_trns(trns)
      @scope.merge!(@scope.where(trn: trns))
    end

    def where_query_matches(query_string)
      return if query_string.blank?

      @scope.merge!(@scope.search(query_string))
    end
  end
end
